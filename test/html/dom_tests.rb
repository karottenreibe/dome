#!/usr/bin/env ruby
require 'test/unit'
require 'dome'

class ParserTests < Test::Unit::TestCase
    include Dome

    def testEmptyElem
        tree = Dome "<doctor />"
        assert_kind_of Tree, tree
        assert_equal 1, tree.root.children.length
        assert_kind_of Element, tree.root.children[0]
        assert_equal :doctor, tree.root.children[0].tag
    end

    def testData
        tree = Dome "<donna>noble</donna>"
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        donna = tree.root.children[0]
        assert_kind_of Element, donna
        assert_equal :donna, donna.tag

        assert_equal false, donna.children.empty?
        noble = donna.children[0]
        assert_kind_of Data, noble
        assert_equal "noble", noble.value
        assert_equal false, noble.cdata?
    end

    def testEmptyAttribute
        tree = Dome "<the doctor />"
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        the = tree.root.children[0]
        assert_kind_of Element, the
        assert_equal :the, the.tag

        assert_equal false, the.attributes.empty?
        doctor = the.attributes[0]
        assert_kind_of Attribute, doctor
        assert_equal :doctor, doctor.name
        assert_equal nil, doctor.value
    end

    def testUnquotedAttribute
        tree = Dome "<martha jones=brilliant />"
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        martha = tree.root.children[0]
        assert_kind_of Element, martha
        assert_equal :martha, martha.tag

        assert_equal false, martha.attributes.empty?
        jones = martha.attributes[0]
        assert_kind_of Attribute, jones
        assert_equal :jones, jones.name
        assert_equal "brilliant", jones.value
    end

    def testQuotedAttribute
        tree = Dome "<rose tyler='marvellous' />"
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        rose = tree.root.children[0]
        assert_kind_of Element, rose
        assert_equal :rose, rose.tag

        assert_equal false, rose.attributes.empty?
        tyler = rose.attributes[0]
        assert_kind_of Attribute, tyler
        assert_equal :tyler, tyler.name
        assert_equal "marvellous", tyler.value
    end

    def testQuotedAttribute2
        tree = Dome '<rose tyler="marvellous" />'
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        rose = tree.root.children[0]
        assert_kind_of Element, rose
        assert_equal :rose, rose.tag

        assert_equal false, rose.attributes.empty?
        tyler = rose.attributes[0]
        assert_kind_of Attribute, tyler
        assert_equal :tyler, tyler.name
        assert_equal "marvellous", tyler.value
    end

    def testNoSpaceAttributes
        tree = Dome "<rose tyler=\"back\"to='earth' />"
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        rose = tree.root.children[0]
        assert_kind_of Element, rose
        assert_equal :rose, rose.tag

        assert_equal 2, rose.attributes.length
        tyler = rose.attributes[0]
        assert_kind_of Attribute, tyler
        assert_equal :tyler, tyler.name
        assert_equal "back", tyler.value

        to = rose.attributes[1]
        assert_kind_of Attribute, to
        assert_equal :to, to.name
        assert_equal "earth", to.value
    end

    def testEscapedAttribute
        tree = Dome "<captain jack='hark\\'ness' />"
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        captain = tree.root.children[0]
        assert_kind_of Element, captain
        assert_equal :captain, captain.tag

        assert_equal 1, captain.attributes.length
        jack = captain.attributes[0]
        assert_kind_of Attribute, jack
        assert_equal :jack, jack.name
        assert_equal "hark'ness", jack.value
    end

    def testCDATA
        tree = Dome "<daleks><![CDATA[are superiour]]></daleks>"
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        daleks = tree.root.children[0]
        assert_kind_of Element, daleks
        assert_equal :daleks, daleks.tag

        assert_equal false, daleks.children.empty?
        cdata = daleks.children[0]
        assert_kind_of Data, cdata
        assert_equal "are superiour", cdata.value
        assert_equal true, cdata.cdata?
    end

    def testSubElements
        tree = Dome "<torchwood><staff>gwen</staff></torchwood>"
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        torchwood = tree.root.children[0]
        assert_kind_of Element, torchwood
        assert_equal :torchwood, torchwood.tag

        assert_equal false, torchwood.children.empty?
        staff = torchwood.children[0]
        assert_kind_of Element, staff
        assert_equal :staff, staff.tag

        assert_equal false, staff.children.empty?
        gwen = staff.children[0]
        assert_kind_of Data, gwen
        assert_equal "gwen", gwen.value
        assert_equal false, gwen.cdata?
    end

    def testMix
        tree = Dome "<sarah>jane<adventures /><![CDATA[[the dog!]]]></sarah>"
        assert_kind_of Tree, tree

        assert_equal false, tree.root.children.empty?
        sarah = tree.root.children[0]
        assert_kind_of Element, sarah
        assert_equal :sarah, sarah.tag

        assert_equal 3, sarah.children.length
        jane = sarah.children[0]
        assert_kind_of Data, jane
        assert_equal "jane", jane.value
        assert_equal false, jane.cdata?

        assert_equal false, sarah.children.empty?
        adventures = sarah.children[1]
        assert_kind_of Element, adventures
        assert_equal :adventures, adventures.tag

        assert_equal false, sarah.children.empty?
        cdata = sarah.children[2]
        assert_kind_of Data, cdata
        assert_equal "[the dog!]", cdata.value
        assert_equal true, cdata.cdata?
    end

    def testTail
        tree = Dome "<shadow />proclamation"
        assert_kind_of Tree, tree

        assert_equal 2, tree.root.children.length
        shadow = tree.root.children[0]
        assert_kind_of Element, shadow
        assert_equal :shadow, shadow.tag

        proclamation = tree.root.children[1]
        assert_kind_of Data, proclamation
        assert_equal "proclamation", proclamation.value
        assert_equal false, proclamation.cdata?
    end

    def testComment
        tree = Dome "<!----->"
        assert_kind_of Tree, tree
        assert_equal 1, tree.root.children.length
        assert_kind_of Comment, tree.root.children[0]
        assert_equal "-", tree.root.children[0].text
    end

    def testEntityExpansion
        tree = Dome "<a b='&amp;'>&lt;</a>", :expand_entities => true
        assert_kind_of Tree, tree
        assert_equal 1, tree.root.children.length
        assert_kind_of Element, tree.root.children[0]
        assert_equal :a, tree.root.children[0].tag
        assert_equal "&", tree.root.children[0][:b]
        assert_equal 1, tree.root.children[0].children.length
        assert_kind_of Data, tree.root.children[0].children[0]
        assert_equal "<", tree.root.children[0].children[0].value
    end

    def testWhitespaceIgnoring
        tree = Dome "  <foo> data  </foo>  ", :ignore_whitespace => true
        assert_kind_of Tree, tree
        assert_equal 1, tree.root.children.length
        assert_kind_of Element, tree.root.children[0]
        assert_equal :foo, tree.root.children[0].tag
        assert_equal 1, tree.root.children[0].children.length
        assert_kind_of Data, tree.root.children[0].children[0]
        assert_equal "data", tree.root.children[0].children[0].value
    end

    def testCaseSensitivity
        tree = Dome "<BAAR:FoOoO loO:xxXxx />", :case_sensitive => true
        assert_kind_of Tree, tree
        assert_equal 1, tree.root.children.length
        assert_kind_of Element, tree.root.children[0]
        assert_equal :FoOoO, tree.root.children[0].tag
        assert_equal :BAAR, tree.root.children[0].namespace
        assert_equal :xxXxx, tree.root.children[0].attributes[0].name
        assert_equal :loO, tree.root.children[0].attributes[0].namespace

        tree = Dome "<BAAR:FoOoO loO:xxXxx />"
        assert_kind_of Tree, tree
        assert_equal 1, tree.root.children.length
        assert_kind_of Element, tree.root.children[0]
        assert_equal :foooo, tree.root.children[0].tag
        assert_equal :baar, tree.root.children[0].namespace
        assert_equal :xxxxx, tree.root.children[0].attributes[0].name
        assert_equal :loo, tree.root.children[0].attributes[0].namespace
    end

end

