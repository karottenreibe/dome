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
    end

end

