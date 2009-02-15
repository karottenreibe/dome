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
# Contains the Parser that can transform a list of Lexer Tokens into a HTML Document.
#

require 'dome/atoms'
require 'dome/lexer'

module Dome

    ##
    # Keeps a Finding of the Parser.
    #
    # The Finding's type can be:
    # - :data
    # - :cdata
    # - :element_start
    # - :element_end
    # - :missing_end
    # - :attribute
    # - :tail
    #
    # The Finding's value depends on it's type:
    # - :data => String
    # - :cdata => String
    # - :element_start => String (tag)
    # - :element_end => String (tag)
    # - :missing_end => String (tag)
    # - :attribute => [String,String|nil]
    # - :tail => String
    #
    primitive :Finding, [:type, :value]

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
            return callcc { |@ret| parse_doc } unless @parse_started
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
        def parse_doc
            @parse_started = true
            goon = true
            goon = parse_element while @lexer.get and goon
            # in case there was an error and there is still data stuff
            parse_tail
            @cc = nil
            @ret.call nil
        end

        ##
        # Parses an element section.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_element
            return false if not @lexer.get or @lexer.get.type != :left_bracket
            trace = @lexer.trace
            @lexer.next!

            tag = parse_text
            return terminate trace unless tag

            found :element_start, tag

            parse_attributes
            parse_whitespace

            if @lexer.get and @lexer.get.type == :empty_element_end
                @lexer.next!
                found :element_end, tag
                return true
            end

            return terminate trace if not @lexer.get or @lexer.get.type != :right_bracket
            @lexer.next!

            parse_children

            end_trace = @lexer.trace
            return missing_end tag, end_trace if not @lexer.get or @lexer.get.type != :end_element_start
            @lexer.next!

            end_tag = parse_text
            return missing_end tag, end_trace if not end_tag or end_tag != tag or not @lexer.get or @lexer.get.type != :right_bracket
            @lexer.next!

            found :element_end, end_tag
            true
        end

        ##
        # Parses all the children of an Element.
        #
        def parse_children
            nil while parse_cdata or parse_data or parse_element
        end

        ##
        # Parses a data section.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_data
            trace = @lexer.trace
            buf = ''

            while token = @lexer.get
                case token.type
                when :cdata_start, :left_bracket, :end_element_start then break true
                else buf << token.value
                end

                @lexer.next!
            end

            return terminate trace if buf.empty?

            found :data, buf
            true
        end

        ##
        # Parses a CDATA section.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_cdata
            return false if not @lexer.get or @lexer.get.type != :cdata_start
            trace = @lexer.trace
            @lexer.next!

            buf = ''

            done = while token = @lexer.get
                @lexer.next!

                case token.type
                when :cdata_end then break true
                else buf << token.value
                end
            end

            found :cdata, buf
            true
        end

        ##
        # Parses all the attributes of an Element, including any preceding whitespace.
        #
        def parse_attributes
            nil while parse_whitespace and parse_attribute
        end

        ##
        # Parses one attribute.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_attribute
            trace = @lexer.trace

            name = parse_text
            return terminate trace if not name

            if not @lexer.get or not @lexer.get.type == :equal
                found :attribute, [name,nil]
                return true
            end

            @lexer.next!

            value = parse_value

            return terminate trace if not value

            found :attribute, [name,value]
            true
        end

        ##
        # Parses one attribute value.
        # Returns the value string on success, +false+ otherwise.
        #
        def parse_value
            trace = @lexer.trace
            quote = false

            if @lexer.get and @lexer.get.type == :quote
                quote = @lexer.get.value
                @lexer.next!
            end
                
            value = parse_text quote
            return terminate trace if not value or
                ( quote and ( not @lexer.get or @lexer.get.type != :quote or
                     @lexer.get.value != quote ) )
            @lexer.next!

            value
        end

        ##
        # Parses 0..* whitespace characters.
        # Always returns +true+.
        #
        def parse_whitespace
            @lexer.next! while @lexer.get and @lexer.get.type == :whitespace
            true
        end

        ##
        # Parses a single text Token, ignoring escaped tokens if +escape+ is true+.
        # Returns either the parsed text or +false+ if no text was recognized.
        #
        def parse_text escape = false
            escaped = false
            buf = ''

            loop do
                token = @lexer.get

                if token and ( token.type == :text or escaped )
                    buf << token.value
                    escaped = false
                elsif escape and token.type == :escape
                    escaped = true
                else
                    break
                end

                @lexer.next!
            end

            buf.empty? ? nil : buf
        end

        ##
        # Parses any remaining input into a data section.
        #
        def parse_tail
            buf = ''

            while token = @lexer.get
                buf << token.value
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
            callcc { |@cc| @ret.call Finding.new(type, value) }
        end

        ##
        # Returns the lexer to the given +trace+ and returns +false+.
        #
        def terminate trace
            @lexer.undo trace
            false
        end

        ##
        # Reports a missing end +tag+, returns the lexer to the +trace+.
        #
        def missing_end tag, trace
            found :missing_end, tag
            @lexer.undo trace
        end

    end

end

