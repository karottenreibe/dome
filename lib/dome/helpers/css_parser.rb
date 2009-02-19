# This is Dome, a pure Ruby HTML DOM parser with very simple XPath support.
#
# If you want to find out more or need a tutorial, go to
# http://dome.rubyforge.org/
# You'll find a nice wiki there!
#
# Author::      Fabian Streitel (karottenreibe)
# Copyright::   Copyright (c) 2008 Fabian Streitel
# License::     Boost Software License 1.0
#               For further information regarding this license, you can go to
#               http://www.boost.org/LICENSE_1_0.txt
#               or read the file LICENSE distributed with this software.
# Homepage::    http://dome.rubyforge.org/
# Git repo::    http://rubyforge.org/scm/?group_id=7589
#
# Contains the Parser that can transform a list of Lexer Tokens into a list of
# CSS Selectors.
#

require 'dome/helpers/lexer'
require 'dome/helpers/finding'

module Dome

    ##
    # Parses a string into a SelectorList. Parsing is started by calling +next+.
    #
    class CSSParser

        ##
        # Initializes the Parser with a given +lexer+.
        #
        def initialize lexer
            @lexer, @parse_started = lexer, false
        end

        ##
        # Starts/continues parsing until the next Finding can be constructed.
        # Returns that Finding (or +nil+ if there are no more).
        #
        def next
            return callcc { |@ret| parse_selectors } unless @parse_started
            # set up a return continuation which will be called when something
            # was parsed successfully
            return callcc { |@ret| @cc.call } if @cc
            nil
        end

        protected

        ##
        # Starts the parsing with the given lexer.
        # Returns +nil+ when parsing has finished.
        #
        def parse_selectors
            @parse_started = true
            goon = true
            goon = parse_selector and parse_operator while @lexer.get and goon
            # in case there was an error and there is still data stuff
            parse_tail
            @cc = nil
            @ret.call nil
        end

        ##
        # Parses a single selector.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_selector
            # looks strange, but has to be that way:
            # first parse an element
            # then parse any additional selectors, regardless of
            # whether there actually was an element matched
            # but do only return true if one of the two matched
            elem = parse_elem_selector
            elem or parse_additional_selectors
        end

        ##
        # Parses a single element selector.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_elem_selector
            return false if not @lexer.get

            case @lexer.get.type
            when :text then found :element, @lexer.get.value
            when :any then found :element, :any
            else return false
            end

            @lexer.next!
            true
        end

        ##
        # Parses attribute, pseudo, id and class selectors.
        # Always returs +true+.
        #
        def parse_additional_selectors
            nil while parse_pseudo_selector or parse_id_selector or
                parse_class_selector or parse_attr_selector
            true
        end

        ##
        # Parses a single attribute selector or nothing.
        # Always returns +true+.
        #
        def parse_attr_selector
            return false if not @lexer.get or @lexer.get.type != :left_bracket
            trace = @lexer.trace
            @lexer.next!
            
            return terminate trace if not @lexer.get or @lexer.get.type != :text
            att = @lexer.get.value
            @lexer.next!

            op = parse_attr_op
            val = nil

            if op
                return terminate trace if not @lexer.get or @lexer.get.type != :text
                val = @lexer.get.value
                @lexer.next!
            end

            return terminate trace if not @lexer.get or @lexer.get.type != :right_bracket
            found :attr, [att,op,val]
            @lexer.next!
            true
        end

        ##
        # Parses an attribute selecotr's operator.
        #
        def parse_attr_op
            return nil unless @lexer.get

            case @lexer.get.type
            when :equal, :in_list, :ends_with, :begins_with, :begins_with_dash, :contains
                @lexer.get.type
            else
                nil
            end
        end

        ##
        # Parses a pseudo selector.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_pseudo_selector
            return false if not @lexer.get or @lexer.get.type != :pseudo
            trace = @lexer.trace
            @lexer.next!

            return terminate trace if not @lexer.get or @lexer.type != :text
            pseudo = @lexer.get
            @lexer.next!

            arg = nil
            if @lexer.get and @lexer.get.type == :parenthesis_left
                @lexer.next!
                arg = parse_pseudo_arg
                return terminate trace if not arg
            end

            found :pseudo, [pseudo,arg]
            true
        end

        ##
        # Parses an argument to a pseudo selector within parenthesis.
        # Assumes that the lexer is positioned after the opening parenthesis.
        # Returns the argument as a String on success and +nil+ otherwise.
        #
        def parse_pseudo_arg
            buf = ''

            done = while @lexer.get
                break true if @lexer.type == :parenthesis_right
                buf << @lexer.get.value
                @lexer.next!
            end

            return nil unless done
            @lexer.next!
            buf
        end

        ##
        # Parses the id selector +#+.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_id_selector
            return false if not @lexer.get or @lexer.get.type != :id
            trace = @lexer.trace
            @lexer.next!

            return terminate trace if not @lexer.get or @lexer.type != :text
            found :attr, ["id",:in_list,@lexer.get.value]
            @lexer.next!
            true
        end

        ##
        # Parses the class selector +.+.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_class_selector
            return false if not @lexer.get or @lexer.get.type != :class
            trace = @lexer.trace
            @lexer.next!

            return terminate trace if not @lexer.get or @lexer.type != :text
            found :attr, ["class",:in_list,@lexer.get.value]
            @lexer.next!
            true
        end

        ##
        # Parses a single operator between selectors.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_operator
            trace = @lexer.trace
            ws = parse_whitespace
            return terminate trace unless @lexer.get

            op = true
            case @lexer.get.type
            when :child then found :child, @lexer.get.value
            when :neighbours then found :neighbour, @lexer.get.value
            when :preceded then found :predecessor, @lexer.get.value
            else op = false
            end

            return false if not ws and not found
            found :ancestor, @lexer.get.value if not found

            @lexer.next!
            parse_whitespace
            true
        end

        ##
        # Parses any number of whitespace characters.
        # Returns +true+ if at least one whitespace was found, else +false+.
        #
        def parse_whitespace
            gotit = false

            while @lexer.get and @lexer.get.type == :whitespace
                @lexer.next!
                gotit = true
            end

            gotit
        end

        ##
        # Parses any tailing values so an error can be thrown.
        #
        def parse_tail
            buf = ''
            buf << @lexer.get.value while @lexer.get
            found :tail, buf unless @buf.empty?
        end

        ##
        # Returns to the return continuation set up in +#next+, returning the
        # given +value+. At the same time it sets up +@cc+ so +#next+ can jump
        # back into the parsing process.
        #
        def found type, value
            callcc { |@cc| @ret.call Finding.new(type, value) }
        end

        ##
        # Returns the lexer to the given +trace+ and returns +false+.
        #
        def terminate trace
            @lexer.undo trace
            false
        end

    end

end

