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
# Contains the HTML instantiation of the Lexer.
#

require 'dome/parsing/lexer'

module Dome

    class HTMLLexer < Lexer
        protected

        def delimiters
            /<!\[CDATA\[|<\/|=|\\|\s|\/>|>|<|\]\]>|'|"/
        end

        def meaning token
            case token
            when '<' then :left_bracket
            when '>' then :right_bracket
            when '=' then :equal
            when '\\' then :escape
            when '"', "'" then :quote
            when /\s/ then :whitespace
            when '/>' then :empty_element_end
            when '</' then :end_element_start
            when '<![CDATA[' then :cdata_start
            when ']]>' then :cdata_end
            else :text
            end
        end
    end

end

