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
require 'lib/dome'
require 'lib/dome/css'

class SelectingTests < Test::Unit::TestCase
    include Dome
    include Selectors

    def setup
        @tree = Dome <<EOI
<root>
    <level1 class=coldplay>
        <level2 value='home'>
            <data id=sleep><![CDATA[blubber]]>blubber</data>
            <nothing class="fu baz">goo!</nothing>
        </level2>
        <empty />
        <data id=1>foo</data>
        <data id=2>bar</data>
    </level1>
    <level11>
        <only id=foo>child</only>
    </level11>
</root>
EOI
    end

    def testElementSelector
        one = @tree/"level2"
        two = @tree%"level2"

        assert_equal [two], one
        assert_kind_of Element, two
        assert_equal "level2", two.tag
    end

    def testAttributeSelector
        %w{= ~= *= ^= $= |=}.each do |sel|
            one = @tree/"[value#{sel}home]"
            two = @tree%"[value#{sel}home]"
            assert_equal [two], one

            assert_kind_of Element, two
            assert_equal "level2", two.tag
        end
    end

    def testStarSelector
        one = @tree/"level11 *"
        two = @tree%"level11 *"
        assert_equal [two], one

        assert_kind_of Element, two
        assert_equal "only", two.tag

        one = @tree/"*"
        assert_equal 10, one.length

        assert_kind_of Element, one[0]
        assert_equal "root", one[0].tag
        assert_kind_of Element, one[1]
        assert_equal "level1", one[1].tag
        assert_kind_of Element, one[2]
        assert_equal "level2", one[2].tag
        assert_kind_of Element, one[3]
        assert_equal "data", one[3].tag
        assert_kind_of Element, one[4]
        assert_equal "nothing", one[4].tag
        assert_kind_of Element, one[5]
        assert_equal "empty", one[5].tag
        assert_kind_of Element, one[6]
        assert_equal "data", one[6].tag
        assert_kind_of Element, one[7]
        assert_equal "data", one[7].tag
        assert_kind_of Element, one[8]
        assert_equal "level11", one[8].tag
        assert_kind_of Element, one[9]
        assert_equal "only", one[9].tag
    end

    def testCombinators
        (%w{> + ~ \ }).each do |op|
            one = @tree/"*#{op}empty"
            two = @tree%"*#{op}empty"
            assert_equal [two], one

            assert_kind_of Element, two
            assert_equal "empty", two.tag
        end
    end

    def testIDClassSelectors
        one = @tree/".coldplay"
        two = @tree%".coldplay"
        assert_equal [two], one

        assert_kind_of Element, two
        assert_equal "level1", two.tag
        assert_equal "coldplay", two[:class]

        one = @tree/"#foo"
        two = @tree%"#foo"
        assert_equal [two], one

        assert_kind_of Element, two
        assert_equal "only", two.tag
        assert_equal "foo", two[:id]
    end

end
