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

