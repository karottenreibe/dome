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
        <only>child</only>
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
            assert_equal one, [two]

            assert_kind_of Element, two
            assert_equal "level2", two.tag
        end
    end

    def testStarSelector
        one = @tree/"level11 *"
        two = @tree%"level11 *"
        assert_equal one, [two]

        assert_kind_of Element, two
        assert_equal "only", two.tag
    end

    def testCombinators
        (%w{> + ~} << " ").each do |op|
            one = @tree/"*#{op}empty"
            two = @tree%"*#{op}empty"
            assert_equal one, [two]

            p op
            assert_kind_of Element, two
            assert_equal "empty", two.tag
        end
    end

end
