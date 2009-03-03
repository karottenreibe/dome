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
require 'dome/parsing/html_parser'

class HTMLParserTests < Test::Unit::TestCase
    include Dome

    def testEmptyElem
        p = HTMLParser.new HTMLLexer.new("<foo/>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:foo], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testData
        p = HTMLParser.new HTMLLexer.new("<bar>data</bar>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:bar], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :data, ret.type
        assert_equal "data", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testEmptyAttribute
        p = HTMLParser.new HTMLLexer.new("<bacon lulu />")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:bacon], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :attribute, ret.type
        assert_equal [nil,:lulu,nil], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testUnquotedAttribute
        p = HTMLParser.new HTMLLexer.new("<bacon lulu=22 />")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:bacon], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :attribute, ret.type
        assert_equal [nil,:lulu,"22"], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testQuotedAttribute
        p = HTMLParser.new HTMLLexer.new("<bacon lala='heckle' />")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:bacon], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :attribute, ret.type
        assert_equal [nil,:lala,"heckle"], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testQuotedAttribute2
        p = HTMLParser.new HTMLLexer.new('<bacon lala="heckle" />')
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:bacon], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :attribute, ret.type
        assert_equal [nil,:lala,"heckle"], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testNoSpaceAttributes
        p = HTMLParser.new HTMLLexer.new("<lester friend='jeff'boss='mike' />")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:lester], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :attribute, ret.type
        assert_equal [nil,:friend,"jeff"], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :attribute, ret.type
        assert_equal [nil,:boss,"mike"], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testEscapedAttribute
        p = HTMLParser.new HTMLLexer.new("<ellie bartowski='gr\\'<>eat' />")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:ellie], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :attribute, ret.type
        assert_equal [nil,:bartowski,"gr'<>eat"], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testCDATA
        p = HTMLParser.new HTMLLexer.new("<random>you<![CDATA[<stuff><<>>\"'''fool]]></random>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:random], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :data, ret.type
        assert_equal "you", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :cdata, ret.type
        assert_equal "<stuff><<>>\"'''fool", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type
    end

    def testSubElements
        p = HTMLParser.new HTMLLexer.new("<extreme><being>mostly</being></extreme>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:extreme], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:being], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :data, ret.type
        assert_equal "mostly", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type
    end

    def testMix
        p = HTMLParser.new HTMLLexer.new("<holographic>and shiny<bees>always look like</bees><![CDATA[being]]><like /></holographic>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:holographic], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :data, ret.type
        assert_equal "and shiny", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:bees], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :data, ret.type
        assert_equal "always look like", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :cdata, ret.type
        assert_equal "being", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:like], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type
    end

    def testTail
        p = HTMLParser.new HTMLLexer.new("<chuck></chuck>bartowski")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:chuck], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :data, ret.type
        assert_equal "bartowski", ret.value
    end

    def testRestNil
        p = HTMLParser.new HTMLLexer.new("demorgan")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :data, ret.type
        assert_equal "demorgan", ret.value

        5.times { assert_kind_of NilClass, p.next }
    end

    def testComment
        p = HTMLParser.new HTMLLexer.new("<!------->")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :comment, ret.type
        assert_equal "---", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testNamespaces
        p = HTMLParser.new HTMLLexer.new("<ns:boo tommy:gun='old'></ns:boo>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [:ns,:boo], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :attribute, ret.type
        assert_equal [:tommy,:gun,"old"], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type

        ret = p.next
        assert_kind_of NilClass, ret
    end

end

