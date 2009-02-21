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
require 'lib/dome/helpers/html_parser'

class FailTests < Test::Unit::TestCase
    include Dome

    def testMissingEndTag
        p = HTMLParser.new HTMLLexer.new("<coolness><empty></coolness>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal "coolness", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal "empty", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :missing_end, ret.type
        assert_equal "empty", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type
        assert_equal "coolness", ret.value
    end

    def testMissingCDATAEnd
        p = HTMLParser.new HTMLLexer.new("<coolness><![CDATA[foo</coolness>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal "coolness", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :cdata, ret.type
        assert_equal "foo</coolness>", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :missing_end, ret.type
        assert_equal "coolness", ret.value
    end

    def testMissingAttributeQuote
        p = HTMLParser.new HTMLLexer.new("<captain awesome='devon></woodcomb>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal "captain", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :tail, ret.type
        assert_equal "<captain awesome='devon></woodcomb>", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testElementWithoutTag
        p = HTMLParser.new HTMLLexer.new("</>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :tail, ret.type
        assert_equal "</>", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testElementUnfinishedAttribute
        p = HTMLParser.new HTMLLexer.new("<morgan anna=/>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal "morgan", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :tail, ret.type
        assert_equal "<morgan anna=/>", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testMissingAttributeValue
        p = HTMLParser.new HTMLLexer.new("<anna wu=/>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal "anna", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :tail, ret.type
        assert_equal "<anna wu=/>", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testEscapedNonQuotedAttribute
        p = HTMLParser.new HTMLLexer.new("<john casey=\"/>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal "john", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :tail, ret.type
        assert_equal "<john casey=\"/>", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testNotMatchingAttributeQuote
        p = HTMLParser.new HTMLLexer.new("<the intersect=\"chuck' />")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal "the", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :tail, ret.type
        assert_equal "<the intersect=\"chuck' />", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

end

