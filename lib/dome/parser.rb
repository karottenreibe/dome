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
    class Finding

        ##
        # The Finding's type:
        # - :data
        # - :cdata
        # - :element_start
        # - :element_end
        # - :missing_end
        # - :attribute
        attr_accessor :type

        ##
        # The Finding's value, depends on it's type.
        # - :data => String
        # - :cdata => String
        # - :element_start => String (tag)
        # - :element_end => String (tag)
        # - :missing_end => String (tag)
        # - :attribute => [String,String|nil]
        attr_accessor :value

        ##
        # Initializes the Finding's +type+ and +value+.
        #
        def initialize type, value
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

        ##
        # Initializes the Parser with a given +lexer+.
        #
        def initialize lexer
            @lexer = lexer
        end

        ##
        # Starts/continues parsing until the next object can be constructed.
        # Returns that object.
        #
        def next
            # set up a return continuation which will be called when someting
            # was parsed successfully
            callcc do |@ret|
                # either return to point in parsing where we left off, or start
                # over if there is no such point
                if @cc then @cc.call
                else parse_doc
                end
            end
        end

        ##
        # Starts the parsing with the given +lexer+.
        # Returns +nil+ when parsing has finished.
        #
        def parse_doc
            parse_element while @lexer.next?
            nil
        end

        ##
        # Parses all the children of an Element.
        # Always returns +true+.
        #
        def parse_children
            nil while parse_cdata or parse_data or parse_element
            true
        end

        ##
        # Parses a data section.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_data
            trace = @lexer.trace
            buf = ''

            done = while @lexer.next?
                token = @lexer.next
                
                case token.type
                when :cdata_start, :left_bracket then break true
                else buf << token.value
                end

                @lexer.next!
            end

            return terminate trace unless done

            found :data, buf
            true
        end

        ##
        # Parses a CDATA section.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_cdata
            trace = @lexer.trace
            return terminate trace if not @lexer.next? or @lexer.next.type != :cdata_start
            @lexer.next!

            buf = ''

            done = while @lexer.next?
                token = @lexer.next!
                
                case token.type
                when :cdata_end then break true
                else buf << token.value
                end
            end
            
            return terminate trace unless done

            found :cdata, buf
            true
        end

        ##
        # Parses an element section.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_element
            trace = @lexer.trace

            return terminate trace if not @lexer.next? or @lexer.next.type != :left_bracket
            lexer.next!

            tag = parse_tag
            return terminate trace unless tag

            found :element_start, tag

            parse_attributes

            if @lexer.next? and @lexer.next.type == :element_end
                @lexer.next!
                found :element_end, tag
                return true
            end

            return terminate trace if not @lexer.next? or @lexer.next.type != :right_bracket
            @lexer.next!

            parse_children

            end_trace = @lexer.trace
            return missing_end tag, end_trace if not @lexer.next? or @lexer.next.type != :left_bracket
            @lexer.next!

            tag = parse_tag
            return missing_end tag, end_trace if not tag or not @lexer.next? or @lexer.next.type != :right_bracket
            @lexer.next!

            found :element_end, tag
            true
        end

        ##
        # Parses an element tag.
        # Returns either the parsed tag or +nil+ if no tag was recognized.
        #
        def parse_tag
            token = @lexer.next

            if @lexer.next? and token.type == :text
                @lexer.next!
                token
            else
                nil
            end
        end

        ##
        # Parses all the attributes of an Element.
        # Always returns +true+.
        #
        def parse_attributes
            nil while parse_attribute
            true
        end

        ##
        # Parses one attribute.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_attribute
            trace = @lexer.trace

            tag = parse_tag
            return terminate trace if not tag

            if not @lexer.next? or not @lexer.next.type == :equal
                found :attribute, [tag,nil]
                return true
            end

            @lexer.next!

            value = parse_value

            return terminate trace if not value

            found :attribute, [tag,value]
            true
        end

        ##
        # Parses one attribute value.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_value
        end

        protected

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
        # Reports a missing end +tag+, returns the lexer to the +trace+ and returns +true+.
        #
        def missing_end tag, trace
            found :missing_end, tag
            @lexer.undo trace
            true
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

