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
require 'dome/css'

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

    def testPseudos
        [RootSelector, OnlyChildSelector, EmptySelector, OnlyTextSelector, ParentSelector].zip(
            %w{:root :only-child :empty :only-text ..}
        ).each do |(klass,exp)|
            p = klass.new
            assert_equal exp, p.inspect
        end

        p = OnlyOfTypeSelector.new "type"
        assert_equal ":only-of-type", p.inspect
    end

    def testNthInspect
        [NthChildSelector,NthOfTypeSelector].zip(
            %w{nth-child nth-of-type},
            [[],["foo"]]
        ).each do |(klass,type,base)|
            [[2,0],[2,1],[3,5],[0,0],[4,0],[0,1],[1,1],[1,0]].zip(
                %w{even odd 3n+5 0 4n 1 n+1 n}
            ).each do |(args,exp)|
                n = klass.new *([args, false] + base)
                assert_equal ":#{type}(#{exp})", n.inspect
            end
        end
    end

    def testEpsNotInspect
        [EpsilonSelector,NotSelector].zip(
            %w{eps not}
        ).each do |(klass,exp)|
            s = klass.new Selector.new("invader > zim")
            assert_equal ":#{exp}(invader > zim)", s.inspect
        end
    end

    def testSelectorInspect
        s = Selector.new "dim[versus] zim"
        assert_equal "#<Dome::Selector {dim[versus] zim}>", s.inspect
    end

end

