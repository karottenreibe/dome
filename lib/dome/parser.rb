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
            pos = @lexer.trace
            buf = ''

            done = while @lexer.next?
                token = @lexer.next
                
                case token.type
                when :cdata_start, :left_bracket then break true
                else buf << token.value
                end

                @lexer.next!
            end

            if done then found Data.new(buf)
            else @lexer.undo pos
            end

            done
        end

        ##
        # Parses a CDATA section.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_cdata
            trace = @lexer.trace
            return false unless @lexer.next? and @lexer.next.type == :cdata_start
            @lexer.next!

            buf = ''

            done = while @lexer.next?
                token = @lexer.next!
                
                case token.type
                when :cdata_end then break true
                else buf << token.value
                end
            end
            
            if done then found Data.new(buf, true)
            else @lexer.undo pos
            end

            done
        end

        ##
        # Parses an element section.
        # Returns +true+ on success and +false+ otherwise.
        #
        def parse_element
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
        end

        protected

        ##
        # Returns to the return continuation set up in +#next+, returning the
        # given +value+. At the same time it sets up +@cc+ so +#next+ can jump
        # back into the parsing process.
        #
        def found value
            callcc { |@cc| @ret.call value }
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

