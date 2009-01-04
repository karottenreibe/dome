#!/usr/bin/env ruby
require 'test/unit'
require 'lib/dome'

class Tests < Test::Unit::TestCase
    include Dome

	def self.val
		@@val
	end

	def self.val= v
		@@val = v
	end

    def testNodes
        doc = '<root><subnode></subnode></root>'
        tree = Dome::parse doc
        assert_equal 1, tree.roots.length
            assert_equal 'root', tree.roots[0].name
            assert_equal 0, tree.roots[0].attributes.length
                assert_equal 1, tree.roots[0].children.length
                assert_equal 'subnode', tree.roots[0].children[0].name
                assert_equal 0, tree.roots[0].children[0].attributes.length
                    assert_equal 0, tree.roots[0].children[0].children.length
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
        doc = '<root><closeme /></root>'
        tree = Dome::parse doc
        assert_equal 1, tree.roots.length
            assert_equal 'root', tree.roots[0].name
                assert_equal 1, tree.roots[0].children.length
                assert_equal 'closeme', tree.roots[0].children[0].name
                assert_equal true, tree.roots[0].children[0].empty?
                    assert_equal 0, tree.roots[0].children[0].children.length
    end

end
