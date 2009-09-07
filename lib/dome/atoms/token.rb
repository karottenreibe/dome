#
# Contains the Token class that is used by the HTMLParser, the CSSParser and the
# two Lexer classes.
#

module Dome

    ##
    # Keeps a Finding of a Parser.
    #
    Token = Struct.new(:type, :value)

end

