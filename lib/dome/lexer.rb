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

require 'generator'

module Dome

    class Token

        ##
        # The type of the token - Symbol
        # Possible values:
        # - :left_bracket
        # - :right_bracket
        # - :equal
        # - :quote
        # - :whitespace
        # - :text
        # - :element_end
        # - :cdata_start
        # - :cdata_end
        attr_accessor :type

        ##
        # The value of the token - String
        attr_accessor :value

        ##
        # Initializes the Token's +type+ and +value+ fields.
        #
        def initialize type, value = nil
            @type, @value = type, value
        end

    end

    ##
    # Splits a given String into small components that are consumed by the Parser.
    #
    class Lexer

        ##
        # Initializes the Lexer with the input +string+.
        #
        def initialize string
            @string, @pos, @tokens, @done = string, 0, [], false
            self.split!
            self.next!
        end

        ##
        # Retrieves the next token from the input.
        #
        def next
            @token
        end

        ##
        # Advances by one token.
        #
        def next!
            if @gen.next? then @token = @gen.next
            else @token = nil
            end
        end

        ##
        # Whether or not the lexer has more tokens in it's storage.
        #
        def next?
            @gen.next?
        end

        ##
        # Returns an object that can be used to backtrack to the current position by calling
        # +undo+.
        #
        def trace
            @gen.dup
        end

        ##
        # Backtraces to the position identified by the +trace+ object.
        #
        def undo trace
            @token = nil
            @gen = trace
        end

        protected

        ##
        # Generates the generator (*g*), which splits the input up into Tokens.
        #
        def split!
            @gen = Generator.new do |gen|
                tokenize do |token|
                    type = 
                        case token
                        when '<' then :left_bracket
                        when '>' then :right_bracket
                        when '=' then :equal
                        when '"', "'" then :quote
                        when /\s/ then :whitespace
                        when '/>' then :element_end
                        when '<![CDATA[' then :cdata_start
                        when ']]>' then :cdata_end
                        else :text
                        end
                    gen.yield Token.new(type, token)
                end
            end

            nil
        end

        ##
        # Splits the input string up into tokens and yields the given block for
        # each of them.
        #
        def tokenize
            delims = /<!\[CDATA\[|=|\s|\/>|>|<|\]\]>|'|"/
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
end

