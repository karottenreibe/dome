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

class Tests < Test::Unit::TestCase
    include Dome

    def testEmpty
        doc = ''
        tree = Dome::parse doc
    end

    def testNodes
        doc = '<root><subnode></subnode></root>'
        tree = Dome::parse doc
        p tree
        assert_equal 1, tree.roots.length
            assert_equal 'root', tree.roots[0].name
            assert_equal 0, tree.roots[0].attributes.length
                assert_equal 1, tree.roots[0].children.length
                assert_equal 'subnode', tree.roots[0].children[0].name
                assert_equal 0, tree.roots[0].children[0].attributes.length
                    assert_equal 0, tree.roots[0].children[0].children.length
    end

    def testRoots
        doc = '<root><subnode></subnode></root><root2></root2>'
        tree = Dome::parse doc
        assert_equal 2, tree.roots.length
            assert_equal 'root', tree.roots[0].name
            assert_equal 0, tree.roots[0].attributes.length
                assert_equal 1, tree.roots[0].children.length
                assert_equal 'subnode', tree.roots[0].children[0].name
                assert_equal 0, tree.roots[0].children[0].attributes.length
                    assert_equal 0, tree.roots[0].children[0].children.length

            assert_equal 'root2', tree.roots[1].name
            assert_equal 0, tree.roots[1].attributes.length
                assert_equal 0, tree.roots[1].children.length
    end

    def testSiblings
        doc = '<root><subnode></subnode><subnode2></subnode2></root>'
        tree = Dome::parse doc
        assert_equal 1, tree.roots.length
            assert_equal 'root', tree.roots[0].name
            assert_equal 0, tree.roots[0].attributes.length
                assert_equal 2, tree.roots[0].children.length
                assert_equal 'subnode', tree.roots[0].children[0].name
                assert_equal 0, tree.roots[0].children[0].attributes.length
                    assert_equal 0, tree.roots[0].children[0].children.length

                assert_equal 'subnode2', tree.roots[0].children[1].name
                assert_equal 0, tree.roots[0].children[1].attributes.length
                    assert_equal 0, tree.roots[0].children[1].children.length
    end

    def testAttributes
        doc = '<root foo=bar loo="lar"><subnode chunky="bacon" bacon="chunky"></subnode></root>'
        tree = Dome::parse doc
        assert_equal 1, tree.roots.length
            assert_equal 'root', tree.roots[0].name
            assert_equal 2, tree.roots[0].attributes.length
            assert_equal 'foo', tree.roots[0].attributes[0].name
            assert_equal 'bar', tree.roots[0].attributes[0].value
            assert_equal 'loo', tree.roots[0].attributes[1].name
            assert_equal 'lar', tree.roots[0].attributes[1].value
                assert_equal 1, tree.roots[0].children.length
                assert_equal 'subnode', tree.roots[0].children[0].name
                assert_equal 2, tree.roots[0].children[0].attributes.length
                assert_equal 'chunky', tree.roots[0].children[0].attributes[0].name
                assert_equal 'bacon', tree.roots[0].children[0].attributes[0].value
                assert_equal 'bacon', tree.roots[0].children[0].attributes[1].name
                assert_equal 'chunky', tree.roots[0].children[0].attributes[1].value
                    assert_equal 0, tree.roots[0].children[0].children.length
    end

    def testAttributesEscaped
        doc = '<root foo=bar><subnode chunky="ba\"con"></subnode></root>'
        tree = Dome::parse doc
        assert_equal 1, tree.roots.length
            assert_equal 'root', tree.roots[0].name
            assert_equal 1, tree.roots[0].attributes.length
            assert_equal 'foo', tree.roots[0].attributes[0].name
            assert_equal 'bar', tree.roots[0].attributes[0].value
                assert_equal 1, tree.roots[0].children.length
                assert_equal 'subnode', tree.roots[0].children[0].name
                assert_equal 1, tree.roots[0].children[0].attributes.length
                assert_equal 'chunky', tree.roots[0].children[0].attributes[0].name
                assert_equal 'ba"con', tree.roots[0].children[0].attributes[0].value
                    assert_equal 0, tree.roots[0].children[0].children.length
    end

    def testDataSolo
        doc = '<root foo=bar><subnode chunky="ba\"con">somedata</subnode></root>'
        tree = Dome::parse doc
        assert_equal 1, tree.roots.length
            assert_equal 'root', tree.roots[0].name
            assert_equal 1, tree.roots[0].attributes.length
            assert_equal 'foo', tree.roots[0].attributes[0].name
            assert_equal 'bar', tree.roots[0].attributes[0].value
                assert_equal 1, tree.roots[0].children.length
                assert_equal 'subnode', tree.roots[0].children[0].name
                assert_equal 1, tree.roots[0].children[0].attributes.length
                assert_equal 'chunky', tree.roots[0].children[0].attributes[0].name
                assert_equal 'ba"con', tree.roots[0].children[0].attributes[0].value
                    assert_equal 1, tree.roots[0].children[0].children.length
                    assert_equal 'somedata', tree.roots[0].children[0].children[0].data
    end

    def testDataMixed
        doc = '<root foo=bar>datata<subnode chunky="ba\"con">somedata</subnode>dududu</root>'
        tree = Dome::parse doc
        assert_equal 1, tree.roots.length
            assert_equal 'root', tree.roots[0].name
            assert_equal 1, tree.roots[0].attributes.length
            assert_equal 'foo', tree.roots[0].attributes[0].name
            assert_equal 'bar', tree.roots[0].attributes[0].value
                assert_equal 3, tree.roots[0].children.length
                assert_equal 'datata', tree.roots[0].children[0].data

                assert_equal 'subnode', tree.roots[0].children[1].name
                assert_equal 1, tree.roots[0].children[1].attributes.length
                assert_equal 'chunky', tree.roots[0].children[1].attributes[0].name
                assert_equal 'ba"con', tree.roots[0].children[1].attributes[0].value
                    assert_equal 1, tree.roots[0].children[1].children.length
                    assert_equal 'somedata', tree.roots[0].children[1].children[0].data

                assert_equal 'dududu', tree.roots[0].children[2].data
    end

    def testSpecialChars
        doc = '<root foo=<bar>da>ta ta<subnode chunky="b\\a\"c<>\\on">som/\edata</subnode>dududu</root>'
        tree = Dome::parse doc
        assert_equal 1, tree.roots.length
            assert_equal 'root', tree.roots[0].name
            assert_equal 1, tree.roots[0].attributes.length
            assert_equal 'foo', tree.roots[0].attributes[0].name
            assert_equal '<bar', tree.roots[0].attributes[0].value
                assert_equal 3, tree.roots[0].children.length
                assert_equal 'da>ta ta', tree.roots[0].children[0].data

                assert_equal 'subnode', tree.roots[0].children[1].name
                assert_equal 1, tree.roots[0].children[1].attributes.length
                assert_equal 'chunky', tree.roots[0].children[1].attributes[0].name
                assert_equal 'b\\a"c<>\\on', tree.roots[0].children[1].attributes[0].value
                    assert_equal 1, tree.roots[0].children[1].children.length
                    assert_equal 'som/\edata', tree.roots[0].children[1].children[0].data

                assert_equal 'dududu', tree.roots[0].children[2].data
    end

    def testEmptyTag
        doc = '<root><closeme args="22"/><closeme2 numba="rumba" /></root>'
        tree = Dome::parse doc
        assert_equal 1, tree.roots.length
            assert_equal 'root', tree.roots[0].name
                assert_equal 2, tree.roots[0].children.length
                assert_equal 'closeme', tree.roots[0].children[0].name
                assert_equal 1, tree.roots[0].children[0].attributes.length
                assert_equal 'args', tree.roots[0].children[0].attributes[0].name
                assert_equal '22', tree.roots[0].children[0].attributes[0].value
                assert_equal true, tree.roots[0].children[0].empty?
                    assert_equal 0, tree.roots[0].children[0].children.length

                assert_equal 'closeme2', tree.roots[0].children[1].name
                assert_equal 1, tree.roots[0].children[1].attributes.length
                assert_equal 'numba', tree.roots[0].children[1].attributes[0].name
                assert_equal 'rumba', tree.roots[0].children[1].attributes[0].value
                assert_equal true, tree.roots[0].children[1].empty?
                    assert_equal 0, tree.roots[0].children[1].children.length
    end

end
