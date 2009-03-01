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
# Shortcut for calling +Dome::Dom.new(input).tree+.
#
def Dome input
    Dome::Dom.new(input).tree
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
        #
        def initialize input
            @parser = HTMLParser.new HTMLLexer.new(input)
            @open, @tree = [], Tree.new
            @cur = @tree.root
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
                    @open << token.value
                    elem = Element.new token.value, @cur
                    @cur.children << elem
                    @cur = elem
                when :element_end, :missing_end
                    close
                when :attribute
                    @cur.attributes << Attribute.new(token.value[0].to_sym, token.value[1])
                when :cdata
                    @cur.children << Data.new(token.value, true)
                when :data, :tail
                    @cur.children << Data.new(token.value)
                when :comment
                    @cur.children << Comment.new(token.value)
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

