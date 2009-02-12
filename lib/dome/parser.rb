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
# Contains the Parser that can transform a String into a HTML Document.
#

require 'dome/atoms'

module Dome

    include Spectre
    include Spectre::StringParsing

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
            @tokens[@pos]
        end

        ##
        # Retrieves the next token from the input and advances by one.
        #
        def next!
            @pos += 1
            @tokens[@pos-1]
        end

        ##
        # Whether or not the lexer has more tokens in it's storage.
        #
        def next?
            @pos < @tokens.length
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

        protected:

            ##
            # Splits the input up into Tokens and stores them in +@tokens+.
            #
            def split!
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
                    @tokens << Token.new type, token
                end
            end

    end

    ##
    # Parses a string into a Document of Elements and Attributes.
    # Parsing is started by calling +parse+.
    #
    class Parser

        class << self

            ##
            # Whether or not the Parser should output warning messages to
            # +STDERR+ when the input is not correct.
            attr_accessor :verbose

        end

        ##
        # Whether or not the parsing process consumed all input.
        attr_reader :consumed_all

        def initialize lexer
            @lexer, @doc = lexer, Document.new
        end

        ##
        # Starts the parsing with the given +lexer+.
        #
        def parse lexer
            while @lexer.next?
                success,elem = parse_element
                
                if success
                    @doc.root.children << elem
                else
                    break
                end
            end

            @doc
        end

        ##
        # Parses the children of an Element.
        # Returns +[success,[chilren]]+
        #
        def parse_children
            parseCDATA or parseData
        end

        ##
        # Parses a data section.
        # Returns +[success,data]+
        #
        def parse_data
            buf = ''

            while @lexer.next?
                token = @lexer.next!
                
                case token.type
                when :cdata_start, :left_bracket then break
                else buf << token.value
                end
            end
            
            [buf.empty?, Data.new(buf)]
        end

        ##
        # Parses a CDATA section.
        # Returns +[success,cdata]+
        #
        def parse_cdata
            return [false, nil] unless @lexer.next? and @lexer.next!.type == :cdata_start

            buf = ''

            while @lexer.next?
                token = @lexer.next!
                
                case token.type
                when :cdata_end then break
                else buf << token.value
                end
            end
            
            [buf.empty?, Data.new(buf, true)]
        end

        ##
        # Parses an element section.
        # Returns +[success,element]+
        #
        def parse_element
        end

        ##
        # Parses an element tag.
        # Returns +[success,tag_string]+
        #
        def parse_tag
            return [false, nil] unless @lexer.next? and @lexer.next.type == :text
            [true, @lexer.next!]
        end

        ##
        # Parses an attribute section.
        # Returns +[success,{name=>value}]+
        #
        def parse_attribute
        end
    end

    class << self
        ##
        # Shortcut for +Dome::Parser.new.parse string+.
        #
        def parse string
            Parser.new( Lexer.new(string) ).parse
        end
    end

end

