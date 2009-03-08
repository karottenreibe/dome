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

require 'dome/atoms/token'

module Dome

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

        ##
        # Returns a String that describes the area from the position within the input given in
        # the +trace+ to the current position and what unexpected +token+ was found.
        #
        def descriptive trace, token
            text =  ''
            trace.upto(@pos) { |i| text << @tokens[i].value if @tokens[i]}
            token = token ? token.type : "end of input"
            "chars (#{trace}..#{trace+text.length}): '#{text}': unexpected #{token}"
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

end

