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

module Dome

    class Token

        ##
        # The type of the token - Symbol
        # Possible values:
        # - :left_bracket
        # - :right_bracket
        # - :equal
        # - :whitespace
        # - :text
        # - :element_end
        # - :cdata_start
        # - :cdata_end
        attr_accessor :type

        ##
        # The value of the token - String or +nil+
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
            @string, @pos, @tokens = string, 0, []
            self.split!
        end

        ##
        # Retrieves the next token from the input.
        #
        def next
            @token = callcc do |@ret|
                if @cc then @cc.call
                else split!
                end
            end unless @token

            @token
        end

        ##
        # Advances by one token.
        #
        def next!
            @token = nil
        end

        ##
        # Whether or not the lexer has more tokens in it's storage.
        #
        def next?
            @done
        end

        ##
        # Returns an object that can be used to backtrack to the current position by calling
        # +undo+.
        #
        def trace
            @cc
        end

        ##
        # Backtraces to the position identified by the +trace+ object.
        #
        def undo trace
            @token = nil
            @cc = trace
        end

        protected

        ##
        # Splits the input up into Tokens.
        #
        def split!
            @done = false

            @string.split(/<|=|\s|\/>|>|<!\[CDATA\[|\]\]>/).each do |token|
                type = 
                    case token
                    when '<' then :left_bracket
                    when '>' then :right_bracket
                    when '=' then :equal
                    when /\s/ then :whitespace
                    when '/>' then :element_end
                    when '<![CDATA[' then :cdata_start
                    when ']]>' then :cdata_end
                    else :text
                    end
                callcc { |@cc| @ret.call Token.new(type, token) }
            end

            @done = true
            nil
        end

    end
end

