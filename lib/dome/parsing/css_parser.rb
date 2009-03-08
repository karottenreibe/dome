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

require 'dome/parsing/css_lexer'
require 'dome/atoms/token'
require 'dome/css'

module Dome

    ##
    # Parses a string into a Selector. Parsing is started by calling +next+.
    #
    class CSSParser

        ##
        # A String describing the last parsing failure that occurred.
        # Will be +nil+ if no failure happened
        #
        attr_accessor :last_failure

        ##
        # Initializes the Parser with a given +lexer+.
        #
        def initialize lexer
            @lexer, @parse_started = lexer, false
        end

        ##
        # Starts/continues parsing until the next Token can be constructed.
        # Returns that Token (or +nil+ if there are no more).
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
            goon = parse_selector and parse_combinator while @lexer.get and goon
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
            # - first try to parse a namespace
            # - then try to parse an element
            # - if the first succeeded but the latter didn't: abort
            # - then try any additional selectors, regardless of
            #   whether there actually was an element or namespace matched
            # but do only return true if
            # - either an element was parsed
            # - or none was parsed and neither was a namespace, and
            #   an additional was parsed
            ns = parse_namespace_selector
            elem = parse_elem_selector
            return terminate "element after namespace selector", trace if ns and not elem
            add = parse_additional_selectors
            elem or ( not ns and add )
        end

        ##
        # Parses a single namespace selector.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_namespace_selector
            return false if not @lexer.get
            trace = @lexer.trace

            ns = nil
            case @lexer.get.type
            when :text
                ns = @lexer.get.value
                @lexer.next!
            when :star
                ns = :any
                @lexer.next!
            end

            return terminate "namespace selector", trace if not @lexer.get or @lexer.get.type != :pipe
            found :namespace, ns
            @lexer.next!

            true
        end

        ##
        # Parses a single element selector.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_elem_selector
            return false if not @lexer.get

            case @lexer.get.type
            when :text then found :element, @lexer.get.value
            when :star then found :element, :any
            else return false
            end

            @lexer.next!
            true
        end

        ##
        # Parses attribute, pseudo selector, id and class selectors.
        # Returns +true+ if at least one selector was parsed, otherwise +false+.
        #
        def parse_additional_selectors
            found = false
            found = true while parse_pseudo_selector or parse_id_selector or
                parse_class_selector or parse_attr_selector or parse_parent_selector
            found
        end

        ##
        # Parses a single attribute selector or nothing.
        # Always returns +true+.
        #
        def parse_attr_selector
            return false if not @lexer.get or @lexer.get.type != :left_bracket
            trace = @lexer.trace
            @lexer.next!
            
            ns = :any
            att = parse_attr_name

            if @lexer.get.type == :pipe
                @lexer.next!
                ns = att
                att = parse_attr_name
                return terminate "attribute selector", trace if not att
            elsif not att
                return terminate "attribute selector", trace
            end

            op = parse_attr_op
            val = nil

            if op
                return terminate "attribute selector", trace if not @lexer.get

                quote = false
                if @lexer.get.type == :quote
                    quote = @lexer.get.value
                    @lexer.next!
                end
                
                val = parse_value quote
                return terminate "attribute selector", trace unless val

                if quote
                    return terminate "attribute selector", trace if not @lexer.get or @lexer.get.type != :quote or @lexer.get.value != quote
                    @lexer.next!
                end
            end

            return terminate "attribute selector", trace if not @lexer.get or @lexer.get.type != :right_bracket
            found :attribute, [ns,att,op,val]
            @lexer.next!
            true
        end

        ##
        # Parses the namespace or attribute name.
        # Returns the name on success and +nil+ otherwise.
        #
        def parse_attr_name
            return nil if not @lexer.get or not [:text,:star].include? @lexer.get.type
            ret = @lexer.get.type == :text ? @lexer.get.value : :any
            @lexer.next!
            ret
        end

        ##
        # Parses an attribute selecotr's operator.
        #
        def parse_attr_op
            return nil unless @lexer.get

            case type = @lexer.get.type
            when :equal, :in_list, :ends_with, :begins_with, :begins_with_dash, :contains, :matches
                @lexer.next!
                type
            else
                nil
            end
        end

        ##
        # Parses a value. If +quote+ is false, it will only parse a single +:text+ Token,
        # else it will recognize +:escape+ Tokens and parse until a matching +quote+ is
        # found or all input is consumed.
        # Return the parsed value on success and +nil+ otherwise
        #
        def parse_value quote = false
            escaped = false
            buf = ''

            loop do
                token = @lexer.get
                break unless token

                if quote and token.type == :escape
                    escaped = true
                elsif (not quote and token.type != :text) or (quote and not escaped and
                    token.type == :quote and token.value == quote)
                    break
                else
                    buf << token.value
                    escaped = false
                end

                @lexer.next!
            end

            buf.empty? ? nil : buf
       end

        ##
        # Parses a pseudo selector.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_pseudo_selector
            allowed = %w{root nth-child nth-last-child nth-of-type nth-last-of-type
                         first-child last-child first-of-type last-of-type
                         only-child only-of-type empty only-text not eps}
            return false if not @lexer.get or @lexer.get.type != :colon
            trace = @lexer.trace
            @lexer.next!

            return terminate "pseudo selector", trace if not @lexer.get or @lexer.get.type != :text
            pseudo = @lexer.get.value
            return terminate "pseudo selector", trace unless allowed.include? pseudo
            @lexer.next!

            arg = nil
            if @lexer.get and @lexer.get.type == :left_parenthesis
                @lexer.next!
                arg = parse_pseudo_arg pseudo
                return terminate "pseudo selector", trace if not arg
            end

            found :pseudo, [pseudo.to_sym,arg]
            true
        end

        ##
        # Parses an argument to the given +pseudo+ selector within parenthesis.
        # Assumes that the lexer is positioned after the opening parenthesis.
        # Returns the argument as a String on success and +nil+ otherwise.
        #
        def parse_pseudo_arg pseudo
            trace = @lexer.trace
            buf = ''
            leftys = 0

            done = while @lexer.get
                if @lexer.get.type == :right_parenthesis
                    if leftys == 0 then break true
                    else leftys -= 1
                    end
                end

                leftys += 1 if @lexer.get.type == :left_parenthesis

                buf << @lexer.get.value
                @lexer.next!
            end

            return nil unless done
            @lexer.next!

            ret =
                case pseudo
                when "not", "eps" then parse_slist_arg buf
                when /^nth-/ then parse_nth_arg buf
                else nil
                end

            terminate "argument to :#{pseudo}", trace unless ret
            ret
        end

        ##
        # Parses the +arg+ument given to +:nth-child()+, +:nth-of-type()+ etc. pseudo selectors.
        # The returned value on success is an Array +[a,b]+ which represents the argument +an\+b+.
        # On failure, this method returns +nil+.
        #
        def parse_nth_arg arg
            case arg
            when "odd" then [2,1]
            when "even" then [2,0]
            when /^-?[0-9]+$/ then [ 0, arg.to_i ]
            when /^n((\+|-)[0-9]+)?$/ then [ 1, arg[1..-1].to_i ]
            when /^-n((\+|-)[0-9]+)?$/ then [ -1, arg[2..-1].to_i ]
            when /^-?[0-9]+n((\+|-)[0-9]+)?$/ then arg.split('n', -1).collect { |x| x.to_i }
            else nil
            end
        end

        ##
        # Parses the +arg+ument given to the +:not()+ and +:eps()+ pseudo selectors.
        # On success returns a Selector which contains the specified selectors.
        # On failure returns +nil+.
        #
        def parse_slist_arg arg
            Selector.new arg
        rescue CSSParsingError => e
            nil
        end

        ##
        # Parses the id selector +#+.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_id_selector
            return false if not @lexer.get or @lexer.get.type != :hash
            trace = @lexer.trace
            @lexer.next!

            return terminate "id selector", trace if not @lexer.get or @lexer.get.type != :text
            found :attribute, [:any,"id",:equal,@lexer.get.value]
            @lexer.next!
            true
        end

        ##
        # Parses the class selector +.+.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_class_selector
            return false if not @lexer.get or @lexer.get.type != :period
            trace = @lexer.trace
            @lexer.next!

            return terminate "class selector", trace if not @lexer.get or @lexer.get.type != :text
            found :attribute, [:any,"class",:in_list,@lexer.get.value]
            @lexer.next!
            true
        end

        ##
        # Parses the parent selector +..+.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_parent_selector
            return false if not @lexer.get or @lexer.get.type != :double_period
            @lexer.next!
            found :parent, nil
            true
        end

        ##
        # Parses a single combinatortor between selectors.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_combinator
            trace = @lexer.trace
            ws = parse_whitespace
            return terminate "combinator", trace unless @lexer.get

            ops = { :chevron => :child,
                    :plus => :neighbour,
                    :rev_chevron => :reverse_neighbour,
                    :percent => :predecessor,
                    :tilde => :follower }

            op = true
            case @lexer.get.type
            when :chevron, :plus, :tilde, :rev_chevron, :percent
                found ops[@lexer.get.type], nil
            else op = false
            end

            return false if not ws and not op
            found :descendant, nil if not op

            @lexer.next! if op
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
            while @lexer.get
                buf << @lexer.get.value
                @lexer.next!
            end
            found :tail, buf unless buf.empty?
        end

        ##
        # Returns to the return continuation set up in +#next+, returning the
        # given +value+. At the same time it sets up +@cc+ so +#next+ can jump
        # back into the parsing process.
        #
        def found type, value
            callcc { |@cc| @ret.call Token.new(type, value) }
        end

        ##
        # Returns the lexer to the given +trace+, stores an error message about +what+ failed to
        # parse and returns +false+.
        #
        def terminate what, trace
            @last_failure = { :what => what, :where => trace, :descriptive => @lexer.descriptive(trace, @lexer.get) }
            @lexer.undo trace
            false
        end

    end

end

