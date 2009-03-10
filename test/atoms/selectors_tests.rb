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
require 'dome/atoms/selectors'

class SelectorsTests < Test::Unit::TestCase
    include Dome
    include Selectors

    def testElementSelectorInspect
        e = ElementSelector.new "U2"
        assert_equal "U2", e.inspect
    end

    def testAttributeSelectorInspect
        %w{equal in_list begins_with begins_with_dash ends_with matches contains}.zip(
            %w{= ~= ^= |= $= /= *=}
        ).each do |(op,exp)|
            a = AttributeSelector.new "ns", "name", op.to_sym, "value\""
            assert_equal "[ns|name#{exp}\"value\\\"\"]", a.inspect
        end
    end

    def testNamespaceSelector
        n = NamespaceSelector.new "Audioslave"
        assert_equal "Audioslave|", n.inspect
    end

    def testCombinators
        [' > ', ' < ', ' % ', ' + ', ' ', ' ~ '].zip(
            [ChildSelector, ReverseNeighbourSelector, PredecessorSelector,
                NeighbourSelector, DescendantSelector, FollowerSelector]
        ).each do |(op,klass)|
            c = klass.new
            assert_equal op, c.inspect
        end
    end

end

