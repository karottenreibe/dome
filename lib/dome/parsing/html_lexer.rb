#
# Contains the HTML instantiation of the Lexer.
#

require 'dome/parsing/lexer'

module Dome

    class HTMLLexer < Lexer
        protected

        def delimiters
            /<!\[CDATA\[|<!--|-->|<\/|=|\\|\s|\/>|>|<|\]\]>|'|"|:/
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
            when '<!--' then :comment_start
            when '-->' then :comment_end
            when '<![CDATA[' then :cdata_start
            when ']]>' then :cdata_end
            when ':' then :colon
            else :text
            end
        end
    end

end

