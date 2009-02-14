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
require 'lib/dome/parser'

class ParserFailTests < Test::Unit::TestCase
    include Dome

    def testMissingEndTag
        return
        p = Parser.new Lexer.new("<random></random>")
        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_start, ret.type
        assert_equal "random", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :cdata, ret.type
        assert_equal "<stuff><<>>\"'''fool", ret.value

        ret = p.next
        assert_kind_of Finding, ret
        assert_equal :element_end, ret.type
        assert_equal "random", ret.value
    end

    def testMissingCDATAEnd
    end

    def testMissingAttributeQuote
    end

end

