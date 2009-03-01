#!/usr/bin/env ruby
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
# Homepage::    http://dome.rubyforge.org/
# Git repo::    http://rubyforge.org/scm/?group_id=7589
#

require 'test/unit'
require 'dome/parsing/html_lexer'

class HTMLLexerTests < Test::Unit::TestCase
    include Dome

    def testText
        lex = HTMLLexer.new "asdf"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "asdf", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testLeftB
        lex = HTMLLexer.new "<foo"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value
    end

    def testRightB
        lex = HTMLLexer.new "<foo>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal ">", t.value
    end

    def testEqual
        lex = HTMLLexer.new "<foo=>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :equal, t.type
        assert_equal "=", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal ">", t.value
    end

    def testQuote
        lex = HTMLLexer.new "<foo=\"'>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :equal, t.type
        assert_equal "=", t.value

        lex.next!
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
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal ">", t.value
    end

    def testWhiteSpace
        lex = HTMLLexer.new "<foo \n\r\f\t>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal " ", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\n", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\r", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\f", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\t", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal ">", t.value
    end

    def testEndElement
        lex = HTMLLexer.new "<foo></foo>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal ">", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :end_element_start, t.type
        assert_equal "</", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal ">", t.value
    end

    def testEmptyElementEnd
        lex = HTMLLexer.new "<foo/>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :empty_element_end, t.type
        assert_equal "/>", t.value
    end

    def testCDATA
        lex = HTMLLexer.new "<![CDATA[" + "chunky_wunky_baconary_timey_wimey_thing..."*10 + "]]>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :cdata_start, t.type
        assert_equal "<![CDATA[", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "chunky_wunky_baconary_timey_wimey_thing..."*10, t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :cdata_end, t.type
        assert_equal "]]>", t.value
    end

    def testTraceUndo
        lex = HTMLLexer.new "<foo='12'>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        trace = lex.trace

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        lex.undo trace

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value
    end

    def testRestNil
        lex = HTMLLexer.new "<![CDATA["
        t = lex.get
        assert_kind_of Token, t
        assert_equal :cdata_start, t.type
        assert_equal "<![CDATA[", t.value

        5.times {
            lex.next!
            assert_kind_of NilClass, lex.get
        }
    end

    def testComment
        lex = HTMLLexer.new "<!------>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :comment_start, t.type
        assert_equal "<!--", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "--", t.value

        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :comment_end, t.type
        assert_equal "-->", t.value

        lex.next!
        assert_kind_of NilClass, lex.get
    end

end

