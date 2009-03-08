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
# Contains the CSS instantiation of the Lexer.
#

require 'dome/parsing/lexer'

module Dome

    class CSSLexer < Lexer
        protected

        def delimiters
            /\[|\]|:|~=|\^=|\$=|\*=|\|=|\/=|\*|=|\(|\)|\.\.|#|\.|>|<|%|\+|,|\s|~|\\|'|"|\|/
        end

        def meaning token
            case token
            when '[' then :left_bracket
            when ']' then :right_bracket
            when '(' then :left_parenthesis
            when ')' then :right_parenthesis
            when '\\' then :escape
            when '"', "'" then :quote
            when /\s/ then :whitespace
            when ':' then :colon
            when '|' then :pipe
            when '*' then :star
            when '.' then :period
            when '..' then :double_period
            when '>' then :chevron
            when '<' then :rev_chevron
            when '+' then :plus
            when '~' then :tilde
            when '%' then :percent
            when '#' then :hash
            when '=' then :equal
            when ',' then :comma
            when '~=' then :in_list
            when '$=' then :ends_with
            when '^=' then :begins_with
            when '*=' then :contains
            when '|=' then :begins_with_dash
            when '/=' then :matches
            else :text
            end
        end
    end

end

