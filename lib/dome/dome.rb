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
# Contains the DOM Parser that converts the Parser Findings into a tree model
# of the HTML document.
#

require 'dome/parsing/html_lexer'
require 'dome/parsing/html_parser'
require 'dome/atoms/nodes'

##
# Shortcut for calling +Dome::Dom.new(*args).tree+.
#
def Dome *args
    Dome::Dom.new(*args).tree
end

module Dome

    ##
    # Takes the input and parses it into a DOM tree.
    #
    class Dom

        ##
        # The tree the DOM Parser produced.
        #
        attr_reader :tree

        ##
        # Parses the +input+. After the creation of the Dom object, the resulting
        # DOM tree will be located in +tree+.
        # The optional +options+ parameter is a Hash that may have any combination of the
        # following entries:
        # - :ignore_whitespace => true -- Ignore whitespace between Nodes
        # - :expand_entities => true -- Autoconvert stuff like '&amp;' --> '&'
        # Any parameter that is not given will be assumed to be +false+.
        #
        def initialize input, options = {}
            @parser = HTMLParser.new HTMLLexer.new(input)
            @open, @tree, @options = [], Tree.new, options
            @cur = @tree.root

            require 'cgi' if @options[:expand_entities]

            parse!
        end
        
        protected

        ##
        # Does the actual parsing by using the +@parser+ to create the +@tree+.
        #
        def parse!
            while token = @parser.next
                case token.type
                when :element_start
                    @open << token.value[1]
                    elem = Element.new token.value[1], token.value[0]
                    elem.parent = @cur
                    @cur = elem
                when :element_end, :missing_end
                    close
                when :attribute
                    val = @options[:expand_entities] ?
                        CGI::unescapeHTML(token.value[2]) :
                        token.value[2]
                    Attribute.new(token.value[1], val, token.value[0]).parent = @cur
                when :cdata
                    val = @options[:ignore_whitespace] ?
                        token.value.strip :
                        token.value
                    val = CGI::unescapeHTML val if @options[:expand_entities]
                    Data.new(val, true).parent = @cur unless val.empty?
                when :data, :tail
                    val = @options[:ignore_whitespace] ?
                        token.value.strip :
                        token.value
                    val = CGI::unescapeHTML val if @options[:expand_entities]
                    Data.new(val).parent = @cur unless val.empty?
                when :comment
                    Comment.new(token.value).parent = @cur
                end
            end

            close until @open.empty?
        end

        def close
            @cur = @cur.parent
            @open.delete_at -1
        end

    end

end

