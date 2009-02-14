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
require 'lib/dome/parser'

class ParserTests < Test::Unit::TestCase
    include Dome

    def testEmptyElem
        p = Parser.new Lexer.new("<foo/>")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "foo", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "foo", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testData
        p = Parser.new Lexer.new("<bar>data</bar>")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "bar", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :data, ret.type
        assert_equal "data", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "bar", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testEmptyAttribute
        p = Parser.new Lexer.new("<bacon lulu />")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "bacon", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :attribute, ret.type
        assert_equal ["lulu",nil], ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "bacon", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testUnquotedAttribute
        p = Parser.new Lexer.new("<bacon lulu=22 />")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "bacon", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :attribute, ret.type
        assert_equal ["lulu","22"], ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "bacon", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testQuotedAttribute
        p = Parser.new Lexer.new("<bacon lala='heckle' />")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "bacon", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :attribute, ret.type
        assert_equal ["lala","heckle"], ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "bacon", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testDoubleQuotedAttribute
        p = Parser.new Lexer.new("<bacon lala=\"heckle\" />")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "bacon", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :attribute, ret.type
        assert_equal ["lala","heckle"], ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "bacon", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testCDATA
        p = Parser.new Lexer.new("<random><![CDATA[<stuff><<>>\"'''fool]]></random>")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "random", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :cdata, ret.type
        assert_equal "<stuff><<>>\"'''fool", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "random", ret.value
    end

    def testSubElements
        p = Parser.new Lexer.new("<extreme><being>mostly</being></extreme>")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "extreme", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "being", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :data, ret.type
        assert_equal "mostly", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "being", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "extreme", ret.value
    end

    def testMix
        p = Parser.new Lexer.new("<holographic>and shiny<bees>always look like</bees><![CDATA[being]]><like /></holographic>")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "holographic", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :data, ret.type
        assert_equal "and shiny", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "bees", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :data, ret.type
        assert_equal "always look like", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "bees", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :cdata, ret.type
        assert_equal "being", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "like", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "like", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "holographic", ret.value
    end

    def testTail
        p = Parser.new Lexer.new("<chuck></chuck>bartowski")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "chuck", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "chuck", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :tail, ret.type
        assert_equal "bartowski", ret.value
    end

    def testRestNil
        p = Parser.new Lexer.new("demorgan")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :tail, ret.type
        assert_equal "demorgan", ret.value

        assert_kind_of NilClass, p.next
        assert_kind_of NilClass, p.next
        assert_kind_of NilClass, p.next
        assert_kind_of NilClass, p.next
    end

end

