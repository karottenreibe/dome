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
            attr_reader :name, :value, :count
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
            assert_equal 'foo', xpath.path[0].attr_parsers[0].name
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
            assert_equal 'foo', xpath.path[0].attr_parsers[0].name
            assert_equal 'bar', xpath.path[0].attr_parsers[0].value
        assert_equal 'p', xpath.path[1].tag
            assert_equal 0, xpath.path[1].attr_parsers.length
        assert_equal 'span', xpath.path[2].tag
            assert_equal 1, xpath.path[2].attr_parsers.length
            assert_equal 'chunky', xpath.path[2].attr_parsers[0].name
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
            assert_equal 'foo', xpath.path[0].attr_parsers[0].name
            assert_equal 'b\'ar', xpath.path[0].attr_parsers[0].value
        assert_equal 'p', xpath.path[1].tag
            assert_equal 0, xpath.path[1].attr_parsers.length
        assert_equal 'span', xpath.path[2].tag
            assert_equal 1, xpath.path[2].attr_parsers.length
            assert_equal 'chunky', xpath.path[2].attr_parsers[0].name
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

    def testFirst
        doc = Dome::parse '<root><subnode>1</subnode><subnode>2</subnode></root>'
        path = "/bad/bad/bad"
        xpath = XPath.new path
        node = xpath.first doc

        #-----

        assert_instance_of NilClass, node

        doc = Dome::parse '<root><subnode>1</subnode><subnode>2</subnode></root>'
        path = "/root"
        xpath = XPath.new path
        node = xpath.first doc

        assert_instance_of Node, node
        assert_equal 'root', node.name

        #-----

        doc = Dome::parse '<root><subnode>1</subnode><subnode>2</subnode></root>'
        path = "/root/subnode"
        xpath = XPath.new path
        node = xpath.first doc

        assert_instance_of Node, node
        assert_equal 'subnode', node.name
            assert_equal 1, node.children.length
            assert_equal '1', node.children[0].data
    end

    def testFirstWithAttributes
        doc = Dome::parse '<root><subnode id="chunky">1</subnode><subnode id="bacon">2</subnode></root>'
        path = "/root/subnode[@id='bacon']"
        xpath = XPath.new path
        node = xpath.first doc

        assert_instance_of Node, node
        assert_equal 'subnode', node.name
            assert_equal 'id', node.attributes[0].name
            assert_equal 'bacon', node.attributes[0].value
            assert_equal 1, node.children.length
            assert_equal '2', node.children[0].data
    end

    def testFirstWithCount
        doc = Dome::parse '<root><subnode id="chunky">1</subnode><subnode id="bacon">2</subnode></root>'
        path = "/root/subnode[1]"

        xpath = XPath.new path
        node = xpath.first doc

        assert_instance_of Node, node
        assert_equal 'subnode', node.name
            assert_equal 'id', node.attributes[0].name
            assert_equal 'chunky', node.attributes[0].value
            assert_equal 1, node.children.length
            assert_equal '1', node.children[0].data

        path = "/root/subnode[last()-1]"

        xpath = XPath.new path
        node = xpath.first doc

        assert_instance_of Node, node
        assert_equal 'subnode', node.name
            assert_equal 'id', node.attributes[0].name
            assert_equal 'chunky', node.attributes[0].value
            assert_equal 1, node.children.length
            assert_equal '1', node.children[0].data

        path = "/root/subnode[last()]"

        xpath = XPath.new path
        node = xpath.first doc

        assert_instance_of Node, node
        assert_equal 'subnode', node.name
            assert_equal 'id', node.attributes[0].name
            assert_equal 'bacon', node.attributes[0].value
            assert_equal 1, node.children.length
            assert_equal '2', node.children[0].data
    end

    def testFirstSomewhere
        doc = Dome::parse '<root><subnode><nope/></subnode><subnode><getme id="first"><getme id="second"/></getme></subnode></root>'
        path = "//getme"
        xpath = XPath.new path
        node = xpath.first doc

        assert_instance_of Node, node
        assert_equal 'getme', node.name
            assert_equal 'id', node.attributes[0].name
            assert_equal 'first', node.attributes[0].value
    end

    def testAll
        doc = Dome::parse '<root><subnode>1</subnode><subnode>2</subnode></root>'
        path = "/bad/worse/worst"
        xpath = XPath.new path
        nodes = xpath.all doc

        assert_equal 0, nodes.length

        #------

        doc = Dome::parse '<root><subnode>1</subnode><subnode>2</subnode></root>'
        path = "/root"
        xpath = XPath.new path
        nodes = xpath.all doc

        assert_equal 1, nodes.length
        assert_equal 'root', nodes[0].name

        #------

        doc = Dome::parse '<root><subnode>1</subnode><subnode>2</subnode></root>'
        path = "/root/subnode"
        xpath = XPath.new path
        nodes = xpath.all doc

        assert_equal 2, nodes.length
        assert_equal 'subnode', nodes[0].name
            assert_equal 1, nodes[0].children.length
            assert_equal '1', nodes[0].children[0].data

        assert_equal 'subnode', nodes[1].name
            assert_equal 1, nodes[1].children.length
            assert_equal '2', nodes[1].children[0].data
    end

    def testAllWithAttributes
        doc = Dome::parse '<root><subnode class="chunkybacon">1</subnode><subnode class="chunkybacon">2</subnode></root>'
        path = "/root/subnode[@class='chunkybacon']"
        xpath = XPath.new path
        nodes = xpath.all doc

        assert_equal 2, nodes.length
        assert_equal 'subnode', nodes[0].name
            assert_equal 'class', nodes[0].attributes[0].name
            assert_equal 'chunkybacon', nodes[0].attributes[0].value

        assert_equal 'subnode', nodes[1].name
            assert_equal 'class', nodes[1].attributes[0].name
            assert_equal 'chunkybacon', nodes[1].attributes[0].value
    end

    def testAllWithCount
        doc = Dome::parse '<root><subnode id="chunky">1</subnode><subnode id="bacon">2</subnode></root>'
        path = "/root/subnode[1]"

        xpath = XPath.new path
        nodes = xpath.all doc

        assert_equal 1, nodes.length
        assert_equal 'subnode', nodes[0].name
            assert_equal 'id', nodes[0].attributes[0].name
            assert_equal 'chunky', nodes[0].attributes[0].value
            assert_equal 1, nodes[0].children.length
            assert_equal '1', nodes[0].children[0].data

        path = "/root/subnode[last()-1]"

        xpath = XPath.new path
        nodes = xpath.all doc

        assert_equal 1, nodes.length
        assert_equal 'subnode', nodes[0].name
            assert_equal 'id', nodes[0].attributes[0].name
            assert_equal 'chunky', nodes[0].attributes[0].value
            assert_equal 1, nodes[0].children.length
            assert_equal '1', nodes[0].children[0].data

        path = "/root/subnode[last()]"

        xpath = XPath.new path
        nodes = xpath.all doc

        assert_equal 1, nodes.length
        assert_equal 'subnode', nodes[0].name
            assert_equal 'id', nodes[0].attributes[0].name
            assert_equal 'bacon', nodes[0].attributes[0].value
            assert_equal 1, nodes[0].children.length
            assert_equal '2', nodes[0].children[0].data
    end

    ##TODO: test empty elements as well
    def testAllSomewhere
        doc = Dome::parse '<root><subnode><nope/></subnode><subnode><getme id="first"><getme id="second"/></getme></subnode></root>'
        path = "//getme"
        xpath = XPath.new path
        nodes = xpath.all doc

        assert_equal 2, nodes.length
        assert_equal 'getme', nodes[0].name
            assert_equal 'id', nodes[0].attributes[0].name
            assert_equal 'first', nodes[0].attributes[0].value

        assert_equal 'getme', nodes[1].name
            assert_equal 'id', nodes[1].attributes[0].name
            assert_equal 'second', nodes[1].attributes[0].value
    end

end

