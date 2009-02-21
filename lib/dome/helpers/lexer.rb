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
# Contains the Lexer that transforms the input String into a list
# of tokens for the Parser.
#

require 'dome/helpers/primitive'

module Dome

    ##
    # Represents a single Token processed by the Lexer.
    #
    primitive :Token, [:type, :value]

    ##
    # Splits a given String into small components that are consumed by the Parser.
    # Needs to be refined by a subclass by providing the +#delimiters+ and +#meaning+
    # methods.
    # +#delimiters+ is expected to return a Regexp that matches all delimiting characters.
    # +#meaning(token)+ is expected to return a symbol, which represents the token's
    # meaning.
    #
    class Lexer

        ##
        # Initializes the Lexer with the input +string+.
        #
        def initialize string
            @string, @pos, @tokens = string, 0, []
            callcc { |@ret| self.split! }
        end

        ##
        # Retrieves the current token from the input.
        #
        def get
            @tokens[@pos]
        end

        ##
        # Advances by one token.
        #
        def next!
            @pos += 1
            callcc { |@ret| @cc.call } if @pos >= @tokens.length and @cc
        end

        ##
        # Returns an object that can be used to backtrack to the current position by calling
        # +undo+.
        #
        def trace
            @pos
        end

        ##
        # Backtraces to the position identified by the +trace+ object.
        #
        def undo trace
            @pos = trace
        end

        protected

        ##
        # Generates the generator (*g*), which splits the input up into Tokens.
        #
        def split!
            first = true

            tokenize do |token|
                callcc { |@cc| @ret.call } unless first
                first = false
                @tokens << Token.new(meaning(token), token)
            end

            @cc = nil
            @ret.call
        end

        ##
        # Splits the input string up into tokens and yields the given block for
        # each of them.
        #
        def tokenize
            delims = delimiters
            pos = 0

            while pos < @string.length
                match = delims.match @string[pos..-1]

                if match
                    yield match.pre_match unless match.pre_match.empty?
                    pos += match[0].length + match.pre_match.length
                    yield match[0]
                else
                    yield @string[pos..-1]
                    break
                end
            end
        end

    end

    class HTMLLexer < Lexer
        protected

        def delimiters
            /<!\[CDATA\[|<\/|=|\\|\s|\/>|>|<|\]\]>|'|"/
        end

        def meaning token
            case token
            when '<' then :left_bracket
            when '>' then :right_bracket
            when '=' then :equal
            when '\\' then :escape
            when '"', "'" then :quote
            when /\s/ then :whitespace
            when '/>' then :empty_element_end
            when '</' then :end_element_start
            when '<![CDATA[' then :cdata_start
            when ']]>' then :cdata_end
            else :text
            end
        end
    end

    class CSSLexer < Lexer
        protected

        def delimiters
            /\[|\]|:|\*|~=|\^=|\$=|\*=|\|=|=|\(|\)|#|\.|>|\+|\s|~|\\|'|"/
        end

        def meaning token
            case token
            when '[' then :left_bracket
            when ']' then :right_bracket
            when '(' then :left_parenthesis
            when ')' then :right_parenthesis
            when '\\' then :escape
            when '"', "'" then :quote
            when /\s/ then :whitespace
            when ':' then :pseudo
            when '*' then :any
            when '.' then :class
            when '>' then :child
            when '+' then :neighbours
            when '~' then :follower
            when '#' then :id
            when '=' then :equal
            when '~=' then :in_list
            when '$=' then :ends_with
            when '^=' then :begins_with
            when '*=' then :contains
            when '|=' then :beginis_with_dash
            else :text
            end
        end
    end

end

