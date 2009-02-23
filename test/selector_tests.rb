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

class SelectorTests < Test::Unit::TestCase
    include Dome
    include Selectors

    def testElement
        sl = SelectorList.new("clone").selectors
        assert_equal 1, sl.length
        assert_kind_of ElementSelector, sl[0]
        assert_equal "clone", sl[0].instance_variable_get(:@tag)
    end

    def testAttribute
        sl = SelectorList.new("bad[wolf]").selectors
        assert_equal 2, sl.length
        assert_kind_of ElementSelector, sl[0]
        assert_equal "bad", sl[0].instance_variable_get(:@tag)
        assert_kind_of AttributeSelector, sl[1]
        assert_equal "wolf", sl[1].instance_variable_get(:@name)
        assert_equal nil, sl[1].instance_variable_get(:@op)
        assert_equal nil, sl[1].instance_variable_get(:@value)

        sl = SelectorList.new("bad[wolf=TARDIS]").selectors
        assert_equal 2, sl.length
        assert_kind_of ElementSelector, sl[0]
        assert_equal "bad", sl[0].instance_variable_get(:@tag)
        assert_kind_of AttributeSelector, sl[1]
        assert_equal "wolf", sl[1].instance_variable_get(:@name)
        assert_equal :equal, sl[1].instance_variable_get(:@op)
        assert_equal "TARDIS", sl[1].instance_variable_get(:@value)

        %w{^= $= *= |= ~=}.zip(%w{begins_with ends_with contains begins_with_dash in_list}).each do |(arg,op)|
            sl = SelectorList.new("doctor[TARDIS#{arg}'Time and Relative Dimensions in Space']").selectors
            assert_equal 2, sl.length
            assert_kind_of ElementSelector, sl[0]
            assert_equal "doctor", sl[0].instance_variable_get(:@tag)
            assert_kind_of AttributeSelector, sl[1]
            assert_equal "TARDIS", sl[1].instance_variable_get(:@name)
            assert_equal op.to_sym, sl[1].instance_variable_get(:@op)
            assert_equal "Time and Relative Dimensions in Space", sl[1].instance_variable_get(:@value)
        end
    end

    def testCombinators
        sl = SelectorList.new("one two > three  +  four~five").selectors
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
            sl = SelectorList.new("phony#{sel}").selectors
            assert_equal 2, sl.length
            assert_kind_of ElementSelector, sl[0]
            assert_equal "phony", sl[0].instance_variable_get(:@tag)
            assert_kind_of klass, sl[1]
        end
    end

end

