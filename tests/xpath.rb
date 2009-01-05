#!/usr/bin/env ruby
require 'test/unit'
require 'lib/dome/parser'
require 'lib/dome/xpath'

module Dome
    class XPath
        attr_reader :path

        class NodeParser
            attr_reader :tag, :attr_parsers
        end

        class AttrParser
            attr_reader :attr, :value, :count
        end
    end
end

class XPathConstructionTests < Test::Unit::TestCase
    include Dome

    def testSingleNode
        path = '/div'
        xpath = XPath.new path

        assert_equal 1, xpath.path.length
        assert_equal 'div', xpath.path[0].tag
            assert_equal 0, xpath.path[0].attr_parsers.length
    end

    def testMultipleNodes
        path = '/div/p/span/em/a'
        xpath = XPath.new path

        assert_equal 5, xpath.path.length
        assert_equal 'div', xpath.path[0].tag
            assert_equal 0, xpath.path[0].attr_parsers.length
        assert_equal 'p', xpath.path[1].tag
            assert_equal 0, xpath.path[1].attr_parsers.length
        assert_equal 'span', xpath.path[2].tag
            assert_equal 0, xpath.path[2].attr_parsers.length
        assert_equal 'em', xpath.path[3].tag
            assert_equal 0, xpath.path[3].attr_parsers.length
        assert_equal 'a', xpath.path[4].tag
            assert_equal 0, xpath.path[4].attr_parsers.length
    end

    def testSingleAttribute
        path = "/div[@foo='bar']/p/span/em/a"
        xpath = XPath.new path

        assert_equal 5, xpath.path.length
        assert_equal 'div', xpath.path[0].tag
            assert_equal 1, xpath.path[0].attr_parsers.length
            assert_equal 'foo', xpath.path[0].attr_parsers[0].attr
            assert_equal 'bar', xpath.path[0].attr_parsers[0].value
        assert_equal 'p', xpath.path[1].tag
            assert_equal 0, xpath.path[1].attr_parsers.length
        assert_equal 'span', xpath.path[2].tag
            assert_equal 0, xpath.path[2].attr_parsers.length
        assert_equal 'em', xpath.path[3].tag
            assert_equal 0, xpath.path[3].attr_parsers.length
        assert_equal 'a', xpath.path[4].tag
            assert_equal 0, xpath.path[4].attr_parsers.length
    end

    def testMultipleAttributes
        path = "/div[@foo='bar']/p/span[@chunky='bacon']/em/a"
        xpath = XPath.new path

        assert_equal 5, xpath.path.length
        assert_equal 'div', xpath.path[0].tag
            assert_equal 1, xpath.path[0].attr_parsers.length
            assert_equal 'foo', xpath.path[0].attr_parsers[0].attr
            assert_equal 'bar', xpath.path[0].attr_parsers[0].value
        assert_equal 'p', xpath.path[1].tag
            assert_equal 0, xpath.path[1].attr_parsers.length
        assert_equal 'span', xpath.path[2].tag
            assert_equal 1, xpath.path[2].attr_parsers.length
            assert_equal 'chunky', xpath.path[2].attr_parsers[0].attr
            assert_equal 'bacon', xpath.path[2].attr_parsers[0].value
        assert_equal 'em', xpath.path[3].tag
            assert_equal 0, xpath.path[3].attr_parsers.length
        assert_equal 'a', xpath.path[4].tag
            assert_equal 0, xpath.path[4].attr_parsers.length
    end

    def testEscapedAttributes
        path = "/div[@foo='b\\'ar']/p/span[@chunky='ba\\\\con']/em/a"
        xpath = XPath.new path

        assert_equal 5, xpath.path.length
        assert_equal 'div', xpath.path[0].tag
            assert_equal 1, xpath.path[0].attr_parsers.length
            assert_equal 'foo', xpath.path[0].attr_parsers[0].attr
            assert_equal 'b\'ar', xpath.path[0].attr_parsers[0].value
        assert_equal 'p', xpath.path[1].tag
            assert_equal 0, xpath.path[1].attr_parsers.length
        assert_equal 'span', xpath.path[2].tag
            assert_equal 1, xpath.path[2].attr_parsers.length
            assert_equal 'chunky', xpath.path[2].attr_parsers[0].attr
            assert_equal 'ba\\con', xpath.path[2].attr_parsers[0].value
        assert_equal 'em', xpath.path[3].tag
            assert_equal 0, xpath.path[3].attr_parsers.length
        assert_equal 'a', xpath.path[4].tag
            assert_equal 0, xpath.path[4].attr_parsers.length
    end

    def testCount
        path = "/div[55]/p/span[last()-3]/em[last()]/a"
        xpath = XPath.new path

        assert_equal 5, xpath.path.length
        assert_equal 'div', xpath.path[0].tag
            assert_equal 1, xpath.path[0].attr_parsers.length
            assert_equal 55, xpath.path[0].attr_parsers[0].count
        assert_equal 'p', xpath.path[1].tag
            assert_equal 0, xpath.path[1].attr_parsers.length
        assert_equal 'span', xpath.path[2].tag
            assert_equal 1, xpath.path[2].attr_parsers.length
            assert_equal -4, xpath.path[2].attr_parsers[0].count
        assert_equal 'em', xpath.path[3].tag
            assert_equal 1, xpath.path[3].attr_parsers.length
            assert_equal -1, xpath.path[3].attr_parsers[0].count
        assert_equal 'a', xpath.path[4].tag
            assert_equal 0, xpath.path[4].attr_parsers.length
    end
end

class XPathScrapingTests < Test::Unit::TestCase
    include Dome

    def testNothing
    end

end
