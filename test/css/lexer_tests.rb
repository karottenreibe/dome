#!/usr/bin/env ruby
require 'test/unit'
require 'dome/parsing/css_lexer'

class CSSLexerTests < Test::Unit::TestCase
    include Dome

    def testLeftBracket
        lex = CSSLexer.new "["
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "[", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testRightBracket
        lex = CSSLexer.new "[]"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "[", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal "]", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testParenthesis
        lex = CSSLexer.new "[()]"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "[", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_parenthesis, t.type
        assert_equal "(", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_parenthesis, t.type
        assert_equal ")", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal "]", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testEscape
        lex = CSSLexer.new "\\"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :escape, t.type
        assert_equal "\\", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testQuotes
        lex = CSSLexer.new "\"'"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :quote, t.type
        assert_equal "\"", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :quote, t.type
        assert_equal "'", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testWhitespace
        lex = CSSLexer.new " \t\r\n\f"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal " ", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\t", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\r", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\n", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\f", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testPseudoNamespace
        lex = CSSLexer.new ":|"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :colon, t.type
        assert_equal ":", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :pipe, t.type
        assert_equal "|", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testClassID
        lex = CSSLexer.new ".#"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :period, t.type
        assert_equal ".", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :hash, t.type
        assert_equal "#", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testCombinators
        lex = CSSLexer.new "+~><%"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :plus, t.type
        assert_equal "+", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :tilde, t.type
        assert_equal "~", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :chevron, t.type
        assert_equal ">", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :rev_chevron, t.type
        assert_equal "<", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :percent, t.type
        assert_equal "%", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testAnyParentOr
        lex = CSSLexer.new "*..,"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :star, t.type
        assert_equal "*", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :double_period, t.type
        assert_equal "..", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :comma, t.type
        assert_equal ",", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testTextAndRestNil
        lex = CSSLexer.new "something-anything"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "something-anything", t.value

        5.times {
            lex.next!
            assert_kind_of NilClass, lex.get
        }
    end

    def testAttrOperators
        lex = CSSLexer.new "~=*==^=$=|=/="
        t = lex.get
        assert_kind_of Token, t
        assert_equal :in_list, t.type
        assert_equal "~=", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :contains, t.type
        assert_equal "*=", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :equal, t.type
        assert_equal "=", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :begins_with, t.type
        assert_equal "^=", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :ends_with, t.type
        assert_equal "$=", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :begins_with_dash, t.type
        assert_equal "|=", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :matches, t.type
        assert_equal "/=", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

end

