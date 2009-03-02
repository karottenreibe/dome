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

require 'dome/parsing/html_lexer'
require 'dome/atoms/token'

module Dome

    ##
    # Parses a string into a Document of Elements and Attributes.
    # Parsing is started by calling +next+.
    #
    class HTMLParser

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
            nil while @lexer.get and parse_children
            # in case there was an error and there is still data stuff
            parse_tail
            @cc = nil
            @ret.call nil
        end

        ##
        # Parses all the children of an Element.
        # Always returns +true+.
        #
        def parse_children
            worked = false
            worked = true while parse_element or parse_comment or parse_cdata or parse_data
            worked
        end

        ##
        # Parses an element section.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_element
            return false if not @lexer.get or @lexer.get.type != :left_bracket
            trace = @lexer.trace
            @lexer.next!

            ns = nil
            tag = parse_text
            return terminate trace unless tag

            if @lexer.get and @lexer.get.type == :namespace
                @lexer.next!
                ns = tag
                tag = parse_text
                return terminate trace unless tag
            end

            found :element_start, [ns,tag]

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
        # Parses an HTML comment.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_comment
            return false unless @lexer.get and @lexer.get.type == :comment_start
            @lexer.next!

            buf = ''
            while token = @lexer.get
                break if token.type == :comment_end
                buf << token.value
                @lexer.next!
            end

            found :comment, buf
            @lexer.next!
            true
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
                when :cdata_start, :left_bracket, :end_element_start then break
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
            @lexer.next!

            buf = ''

            while token = @lexer.get
                @lexer.next!

                case token.type
                when :cdata_end then break
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
            return terminate trace if not value

            if quote
                return terminate trace if not @lexer.get or @lexer.get.type != :quote or
                     @lexer.get.value != quote
                @lexer.next!
            end

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
        # Parses a single text Token, ignoring escaped tokens if +quote+ is not +false+.
        # In that case, +quote+ is expected to be the character used as +quote+.
        # Returns either the parsed text or +nil+ if no text was recognized.
        #
        def parse_text quote = false
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
            callcc { |@cc| @ret.call Token.new(type, value) }
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

