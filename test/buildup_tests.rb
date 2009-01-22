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
require 'rubygems'
require 'spectre/spectre'
require 'spectre/std/string'

class Tests < Test::Unit::TestCase
    include Spectre
    include Spectre::StringParsing

    def testTag
        element = Grammar.new do ||
            var :tagname   => ( ~char('>') & ~char(' ') ).+,
                :parser    => char('<') >> :tagname >> string('></') >> :tagname >> char('>')
        end

        ret = parse '<foo></foo>', element
        assert_kind_of Spectre::Match, ret
        assert_equal 11, ret.length

        ret = parse '<foo></bar>', element
        assert_kind_of Spectre::Match, ret
        assert_equal 11, ret.length
    end

    def testTagClosure
        element = Grammar.new do ||
            var :tagname   => ( ~char('>') & ~char(' ') ).+,
                :element   => char('<') >> sym(:tagname)[:tag] >> string('></') >> closed(:tag) >> char('>'),
                :parser    => close(:element)
        end

        ret = parse '<foo></foo>', element
        assert_kind_of Spectre::Match, ret
        assert_equal 11, ret.length

        ret = parse '<foo></bar>', element
        assert_kind_of NilClass, ret
    end

    def testData
        element = Grammar.new do ||
            var :tagname   => ( ~char('>') & ~char(' ') ).+,
                :element   => char('<') >> sym(:tagname)[:tag] >> char('>') >> :data >> string('</') >> closed(:tag) >> char('>'),
                :data      => ( ~char('<') ).*,
                :parser    => close(:element)
        end

        ret = parse '<foo></foo>', element
        assert_kind_of Spectre::Match, ret
        assert_equal 11, ret.length

        ret = parse '<foo>data</foo>', element
        assert_kind_of Spectre::Match, ret
        assert_equal 15, ret.length

        ret = parse '<foo><</foo>', element
        assert_kind_of NilClass, ret

        ret = parse '<foo></bar>', element
        assert_kind_of NilClass, ret
    end

    class Element
        attr_accessor :tag, :attributes, :data
    end

    class Data
        attr_accessor :data
    end

    def testNodeAction
        val = 1

        newelement_a = lambda { |match, closure|
            closure[:element] = Element.new
            closure[:element].tag = match.value
            val += val
        }

        element = Grammar.new do ||
            var :tagname   => ( ~char('>') & ~char(' ') ).+,
                :element   => char('<') >> sym(:tagname)[:tag][newelement_a] >> char('>') >> :data >> string('</') >> closed(:tag) >> char('>'),
                :data      => ( ~char('<') ).*,
                :parser    => :element
        end

        element.closure = Closure.new
        

        ret = parse '<foo></foo>', element
        assert_kind_of Spectre::Match, ret
        assert_equal 11, ret.length

        ret = parse '<foo>data</foo>', element
        assert_kind_of Spectre::Match, ret
        assert_equal 15, ret.length

        ret = parse '<foo><</foo>', element
        assert_kind_of NilClass, ret

        ret = parse '<foo></bar>', element
        assert_kind_of NilClass, ret
        
        assert_equal 16, val
    end

    def testDataAction
    end

end

