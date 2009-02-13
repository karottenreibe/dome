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
require 'lib/dome/lexer'

class LexerTests < Test::Unit::TestCase
    include Dome

    def testText
        lex = Lexer.new "asdf"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "asdf", t.value

        assert_equal false, lex.next?
        lex.next!
        assert_kind_of NilClass, lex.get
    end

    def testLeftB
        lex = Lexer.new "<foo"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value
        assert_equal false, lex.next?
    end

    def testRightB
        lex = Lexer.new "<foo>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal ">", t.value
        assert_equal false, lex.next?
    end

    def testEqual
        lex = Lexer.new "<foo=>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :equal, t.type
        assert_equal "=", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal ">", t.value
        assert_equal false, lex.next?
    end

    def testQuote
        lex = Lexer.new "<foo=\"'>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :equal, t.type
        assert_equal "=", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :quote, t.type
        assert_equal "\"", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :quote, t.type
        assert_equal "'", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal ">", t.value
        assert_equal false, lex.next?
    end

    def testWhiteSpace
        lex = Lexer.new "<foo \n\r\f\t>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal " ", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\n", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\r", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\f", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :whitespace, t.type
        assert_equal "\t", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :right_bracket, t.type
        assert_equal ">", t.value
        assert_equal false, lex.next?
    end

    def testElementEnd
        lex = Lexer.new "<foo/>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :element_end, t.type
        assert_equal "/>", t.value
        assert_equal false, lex.next?
    end

    def testCDATA
        lex = Lexer.new "<![CDATA[chunky_wunky_baconary_timey_wimey_thing...]]>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :cdata_start, t.type
        assert_equal "<![CDATA[", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "chunky_wunky_baconary_timey_wimey_thing...", t.value

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :cdata_end, t.type
        assert_equal "]]>", t.value
        assert_equal false, lex.next?
    end

    def testTraceUndo
        lex = Lexer.new "<foo='12'>"
        t = lex.get
        assert_kind_of Token, t
        assert_equal :left_bracket, t.type
        assert_equal "<", t.value

        trace = lex.trace

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value

        lex.undo trace

        assert_equal true, lex.next?
        lex.next!
        t = lex.get
        assert_kind_of Token, t
        assert_equal :text, t.type
        assert_equal "foo", t.value
    end

end

