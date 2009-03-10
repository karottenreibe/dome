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
require 'dome/atoms/nodes'

class NodesTests < Test::Unit::TestCase
    include Dome

    def testEmptyAttributeInpsect
        a = Attribute.new :MI6
        assert_equal "MI6", a.inspect
    end

    def testAttributeInspect
        a = Attribute.new :CIA, "NSA", :ATF
        assert_equal 'ATF:CIA="NSA"', a.inspect
    end

    def testAttributeEscapeInspect
        a = Attribute.new :FBI, "really\"..."
        assert_equal 'FBI="really\"..."', a.inspect
    end

    def testDataInspect
        %w{foo bar" bubbly< goo'\ goo}.zip(
            %w{foo bar\" bubbly< goo'\ goo}
        ).each do |(word,exp)|
            d = Data.new word
            assert_equal "\"#{exp}\"", d.inspect
            d = Data.new word, true
            assert_equal "\"<![CDATA[#{exp}]]>\"", d.inspect
        end
    end

    def testCommentInspect
        c = Comment.new "foo--bar--boo'\"<>"
        assert_equal "<!-- foo--bar--boo'\"<> -->", c.inspect
    end

    def testEmptyElementInspect
        e = Element.new :peter, :artist
        e.attributes << Attribute.new(:fox, "stadtaffe")
        assert_equal "<artist:peter fox=\"stadtaffe\"/>", e.inspect
    end

    def testElementInspect
        e = Element.new :muse, :alternative
        e.attributes << Attribute.new(:is, "good")
        e.children << Data.new("test")
        e.children << Element.new(:child)
        e.children[1].children << Data.new("nother test")
        assert_equal '<alternative:muse is="good"> "test" <child> "nother test"' +
            ' </child> </alternative:muse>', e.inspect
    end

    def testInnerText
        e = Element.new :pseudo
        e.children << Data.new("0")
        e.children << Element.new(:child)
        e.children[1].children << Data.new("123456")
        e.children << Element.new(:child)
        e.children[2].children << Data.new("789")
        e.children << Element.new(:child)
        assert_equal '0123456789', e.inner_text
    end

    def testInnerHTML
        e = Element.new :pseudo
        e.children << Data.new("0")
        e.children << Element.new(:child)
        e.children[1].children << Data.new("123456")
        e.children << Element.new(:child)
        e.children[2].children << Data.new("789")
        e.children << Element.new(:child)
        e.children[3].attributes << Attribute.new(:empty)
        assert_equal '0<child>123456</child><child>789</child><child empty/>', e.inner_html
    end

    def testOuterHTML
        e = Element.new :pseudo
        e.attributes << Attribute.new(:empty, "false")
        e.children << Data.new("0")
        e.children << Element.new(:child)
        e.children[1].children << Data.new("123456")
        e.children << Element.new(:child)
        e.children[2].children << Data.new("789")
        e.children << Element.new(:child)
        e.children[3].attributes << Attribute.new(:empty)
        assert_equal '<pseudo empty="false">0<child>123456</child><child>789</child><child empty/></pseudo>', e.outer_html
    end

end

