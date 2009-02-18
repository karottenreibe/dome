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
            parse_elem_selector and parse_additional_selectors
        end

        ##
        # Parses attribute, pseudo, id and class selectors.
        # Always returs +true+.
        #
        def parse_additional_selectors
            nil while parse_attr_selector or parse_pseudo_selector or
                parse_id_selector or parse_class_selector
            true
        end

        ##
        # Parses a pseudo selector.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_pseudo_selector
        end

        ##
        # Parses the id selector +#+.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_id_selector
            return false if not @lexer.get or @lexer.get.type != :id
            trace = @lexer.trace
            @lexer.next!

            #TODO: quoted? stuff that is not text?
            return terminate trace if not @lexer.get or @lexer.type != :text
            @lexer.next!
            true
        end

        ##
        # Parses the class selector +.+.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_class_selector
        end

        ##
        # Parses a single element selector.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_elem_selector
        end

        ##
        # Parses a single attribute selector or nothing.
        # Always returns +true+.
        #
        def parse_attr_selector
            return false if not @lexer.get or @lexer.get.type != :left_bracket
            trace = @lexer.trace
            @lexer.next!
            
            #TODO
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
            when :child then found :op_child, @lexer.get.value
            when :neighbours then found :op_neighbours, @lexer.get.value
            when :preceded then found :op_preceded, @lexer.get.value
            else op = false
            end

            return false if not ws and not found
            found :op_ancestor, @lexer.get.value if not found

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

