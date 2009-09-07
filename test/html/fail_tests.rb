#!/usr/bin/env ruby
require 'test/unit'
require 'dome/parsing/html_parser'

class FailTests < Test::Unit::TestCase
    include Dome

    def testMissingEndTag
        p = HTMLParser.new HTMLLexer.new("<coolness><empty></coolness>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:coolness], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:empty], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :missing_end, ret.type

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_end, ret.type
    end

    def testMissingCDATAEnd
        p = HTMLParser.new HTMLLexer.new("<coolness><![CDATA[foo</coolness>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:coolness], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :cdata, ret.type
        assert_equal "foo</coolness>", ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :missing_end, ret.type
    end

    def testMissingAttributeQuote
        p = HTMLParser.new HTMLLexer.new("<captain awesome='devon></woodcomb>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [nil,:captain], ret.value

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
        assert_equal [nil,:morgan], ret.value

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
        assert_equal [nil,:anna], ret.value

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
        assert_equal [nil,:john], ret.value

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
        assert_equal [nil,:the], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :tail, ret.type
        assert_equal "<the intersect=\"chuck' />", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

    def testNotMatchingNamespaces
        p = HTMLParser.new HTMLLexer.new("<best:buddies></any:buddies>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [:best,:buddies], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :missing_end, ret.type

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :tail, ret.type
        assert_equal "</any:buddies>", ret.value

        ret = p.next
        assert_kind_of NilClass, ret

        p = HTMLParser.new HTMLLexer.new("<best:buddies></buddies>")
        ret = p.next
        assert_kind_of Token, ret
        assert_equal :element_start, ret.type
        assert_equal [:best,:buddies], ret.value

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :missing_end, ret.type

        ret = p.next
        assert_kind_of Token, ret
        assert_equal :tail, ret.type
        assert_equal "</buddies>", ret.value

        ret = p.next
        assert_kind_of NilClass, ret
    end

end

