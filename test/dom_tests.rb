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

class ParserTests < Test::Unit::TestCase
    include Dome

    def testEmptyElem
        tree = Dome "<doctor />"
        assert_kind_of Tree, tree
        assert_equal false, tree.root.children.empty?
        assert_kind_of Element, tree.root.children[0]
        assert_equal "doctor", tree.root.children[0].tag
    end

    def testData
        tree = Dome "<donna>noble</donna>"
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        donna = tree.root.children[0]
        assert_kind_of Element, donna
        assert_equal "donna", donna.tag

        assert_equal false, donna.children.empty?
        noble = donna.children[0]
        assert_kind_of Data, noble
        assert_equal "noble", noble.value
        assert_equal false, noble.cdata
    end

    def testEmptyAttribute
        tree = Dome "<the doctor />"
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        the = tree.root.children[0]
        assert_kind_of Element, the
        assert_equal "the", the.tag

        assert_equal false, the.attributes.empty?
        doctor = the.attributes[0]
        assert_kind_of Attribute, doctor
        assert_equal "doctor", doctor.name
        assert_equal nil, doctor.value
    end

end

