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
require 'lib/dome/css'

class CSSParserTests < Test::Unit::TestCase
    include Dome

    def testElement
        p = CSSParser.new CSSLexer.new("batman")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "batman", f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttr
        p = CSSParser.new CSSLexer.new("the[joker]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "the", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["joker",nil,nil], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttrInList
        p = CSSParser.new CSSLexer.new("bruce[wayne~=awesome]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "bruce", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["wayne",:in_list,"awesome"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttrContains
        p = CSSParser.new CSSLexer.new("white[knight*=twoface]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "white", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["knight",:contains,"twoface"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttrBeginsWith
        p = CSSParser.new CSSLexer.new("the[story^=gordon]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "the", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["story",:begins_with,"gordon"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttrEndsWith
        p = CSSParser.new CSSLexer.new("the[film$=batpod]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "the", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["film",:ends_with,"batpod"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttrBeginsWithDash
        p = CSSParser.new CSSLexer.new("first[movie|=batman-begins]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "first", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["movie",:begins_with_dash,"batman-begins"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

end

