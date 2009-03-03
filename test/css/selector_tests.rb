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

class SelectorTests < Test::Unit::TestCase
    include Dome
    include Selectors

    def testElement
        sl = Selector.new("clone").selectors
        assert_equal 1, sl.length
        assert_kind_of ElementSelector, sl[0]
        assert_equal "clone", sl[0].instance_variable_get(:@tag)
    end

    def testAttribute
        sl = Selector.new("bad[wolf]").selectors
        assert_equal 2, sl.length
        assert_kind_of ElementSelector, sl[0]
        assert_equal "bad", sl[0].instance_variable_get(:@tag)
        assert_kind_of AttributeSelector, sl[1]
        assert_equal :wolf, sl[1].instance_variable_get(:@name)
        assert_equal nil, sl[1].instance_variable_get(:@op)
        assert_equal nil, sl[1].instance_variable_get(:@value)

        sl = Selector.new("bad[wolf=TARDIS]").selectors
        assert_equal 2, sl.length
        assert_kind_of ElementSelector, sl[0]
        assert_equal "bad", sl[0].instance_variable_get(:@tag)
        assert_kind_of AttributeSelector, sl[1]
        assert_equal :wolf, sl[1].instance_variable_get(:@name)
        assert_equal :equal, sl[1].instance_variable_get(:@op)
        assert_equal "TARDIS", sl[1].instance_variable_get(:@value)

        %w{^= $= *= |= ~=}.zip(%w{begins_with ends_with contains begins_with_dash in_list matches}).each do |(arg,op)|
            sl = Selector.new("doctor[TARDIS#{arg}'Time and Relative Dimensions in Space']").selectors
            assert_equal 2, sl.length
            assert_kind_of ElementSelector, sl[0]
            assert_equal "doctor", sl[0].instance_variable_get(:@tag)
            assert_kind_of AttributeSelector, sl[1]
            assert_equal :TARDIS, sl[1].instance_variable_get(:@name)
            assert_equal op.to_sym, sl[1].instance_variable_get(:@op)
            assert_equal "Time and Relative Dimensions in Space", sl[1].instance_variable_get(:@value)
        end
    end

    def testCombinators
        sl = Selector.new("one two > three  +  four~five").selectors
        assert_equal 9, sl.length
        assert_kind_of ElementSelector, sl[0]
        assert_equal "one", sl[0].instance_variable_get(:@tag)
        assert_kind_of DescendantSelector, sl[1]
        assert_kind_of ElementSelector, sl[2]
        assert_equal "two", sl[2].instance_variable_get(:@tag)
        assert_kind_of ChildSelector, sl[3]
        assert_kind_of ElementSelector, sl[4]
        assert_equal "three", sl[4].instance_variable_get(:@tag)
        assert_kind_of NeighbourSelector, sl[5]
        assert_kind_of ElementSelector, sl[6]
        assert_equal "four", sl[6].instance_variable_get(:@tag)
        assert_kind_of FollowerSelector, sl[7]
        assert_kind_of ElementSelector, sl[8]
        assert_equal "five", sl[8].instance_variable_get(:@tag)
    end

    def testNoArgPseudos
        %w{:root :only-child :only-of-type :empty :only-text}.zip(
            [RootSelector, OnlyChildSelector, OnlyOfTypeSelector, EmptySelector, OnlyTextSelector]
        ).each do |(sel,klass)|
            sl = Selector.new("phony#{sel}").selectors
            assert_equal 2, sl.length
            assert_kind_of ElementSelector, sl[0]
            assert_equal "phony", sl[0].instance_variable_get(:@tag)
            assert_kind_of klass, sl[1]
        end
    end

    def testNoArgNthPseudos
        %w{:first-child :last-child :first-of-type :last-of-type}.zip(
            [NthChildSelector, NthChildSelector, NthOfTypeSelector, NthOfTypeSelector],
            [false, true, false, true],
            [nil, nil, "buddy", "buddy"]
        ).each do |(sel,klass,reverse, tag)|
            sl = Selector.new("buddy#{sel}").selectors
            assert_equal 2, sl.length
            assert_kind_of ElementSelector, sl[0]
            assert_equal "buddy", sl[0].instance_variable_get(:@tag)
            assert_kind_of klass, sl[1]
            assert_equal [0,1], sl[1].instance_variable_get(:@args)
            assert_equal reverse, sl[1].instance_variable_get(:@reverse)
            assert_equal tag, sl[1].instance_variable_get(:@tag)
        end
    end

    def testArgNthPseudos
        %w{:nth-child :nth-last-child :nth-of-type :nth-last-of-type}.zip(
            [NthChildSelector, NthChildSelector, NthOfTypeSelector, NthOfTypeSelector],
            [false, true, false, true],
            [nil, nil, "guy", "guy"]
        ).each do |(sel,klass,reverse, tag)|
            sl = Selector.new("guy#{sel}(2n+3)").selectors
            assert_equal 2, sl.length
            assert_kind_of ElementSelector, sl[0]
            assert_equal "guy", sl[0].instance_variable_get(:@tag)
            assert_kind_of klass, sl[1]
            assert_equal [2,3], sl[1].instance_variable_get(:@args)
            assert_equal reverse, sl[1].instance_variable_get(:@reverse)
            assert_equal tag, sl[1].instance_variable_get(:@tag)
        end
    end

    def testIDClassSelectors
        sl = Selector.new(".buddy#guy").selectors
        assert_equal 2, sl.length
        assert_kind_of AttributeSelector, sl[0]
        assert_equal :class, sl[0].instance_variable_get(:@name)
        assert_equal :in_list, sl[0].instance_variable_get(:@op)
        assert_equal "buddy", sl[0].instance_variable_get(:@value)

        assert_kind_of AttributeSelector, sl[1]
        assert_equal :id, sl[1].instance_variable_get(:@name)
        assert_equal :equal, sl[1].instance_variable_get(:@op)
        assert_equal "guy", sl[1].instance_variable_get(:@value)
    end

    def testNot
        sl = Selector.new(":not(in > the[mood=for]:not(:root))").selectors
        assert_equal 1, sl.length
        assert_kind_of NotSelector, sl[0]

        inner = sl[0].instance_variable_get :@slist
        assert_kind_of Selector, inner

        sli = inner.selectors
        assert_equal 5, sli.length
        assert_kind_of ElementSelector, sli[0]
        assert_equal "in", sli[0].instance_variable_get(:@tag)

        assert_kind_of ChildSelector, sli[1]

        assert_kind_of ElementSelector, sli[2]
        assert_equal "the", sli[2].instance_variable_get(:@tag)

        assert_kind_of AttributeSelector, sli[3]
        assert_equal :mood, sli[3].instance_variable_get(:@name)
        assert_equal :equal, sli[3].instance_variable_get(:@op)
        assert_equal "for", sli[3].instance_variable_get(:@value)

        assert_kind_of NotSelector, sli[4]

        inner = sli[4].instance_variable_get :@slist
        assert_kind_of Selector, inner

        sli = inner.selectors
        assert_equal 1, sli.length
        assert_kind_of RootSelector, sli[0]
    end

    def testNamespaces
        sl = Selector.new("clone|wars").selectors
        assert_equal 2, sl.length
        assert_kind_of NamespaceSelector, sl[0]
        assert_equal "clone", sl[0].instance_variable_get(:@ns)
        assert_kind_of ElementSelector, sl[1]
        assert_equal "wars", sl[1].instance_variable_get(:@tag)

        sl = Selector.new("*|wars").selectors
        assert_equal 2, sl.length
        assert_kind_of NamespaceSelector, sl[0]
        assert_equal :any, sl[0].instance_variable_get(:@ns)
        assert_kind_of ElementSelector, sl[1]
        assert_equal "wars", sl[1].instance_variable_get(:@tag)

        sl = Selector.new("|wars").selectors
        assert_equal 2, sl.length
        assert_kind_of NamespaceSelector, sl[0]
        assert_equal nil, sl[0].instance_variable_get(:@ns)
        assert_kind_of ElementSelector, sl[1]
        assert_equal "wars", sl[1].instance_variable_get(:@tag)

        sl = Selector.new("[clone|wars]").selectors
        assert_equal 1, sl.length
        assert_kind_of AttributeSelector, sl[0]
        assert_equal "clone", sl[0].instance_variable_get(:@ns)
        assert_equal :wars, sl[0].instance_variable_get(:@name)
        assert_equal nil, sl[0].instance_variable_get(:@op)
        assert_equal nil, sl[0].instance_variable_get(:@value)

        sl = Selector.new("[*|wars]").selectors
        assert_equal 1, sl.length
        assert_kind_of AttributeSelector, sl[0]
        assert_equal :any, sl[0].instance_variable_get(:@ns)
        assert_equal :wars, sl[0].instance_variable_get(:@name)
        assert_equal nil, sl[0].instance_variable_get(:@op)
        assert_equal nil, sl[0].instance_variable_get(:@value)

        sl = Selector.new("[|wars]").selectors
        assert_equal 1, sl.length
        assert_kind_of AttributeSelector, sl[0]
        assert_equal nil, sl[0].instance_variable_get(:@ns)
        assert_equal :wars, sl[0].instance_variable_get(:@name)
        assert_equal nil, sl[0].instance_variable_get(:@op)
        assert_equal nil, sl[0].instance_variable_get(:@value)
    end

    def testParent
        sl = Selector.new("..").selectors
        assert_equal 1, sl.length
        assert_kind_of ParentSelector, sl[0]
    end

end

