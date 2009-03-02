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
require 'dome/css'

class CSSParserTests < Test::Unit::TestCase
    include Dome
    include Selectors

    def testElement
        p = CSSParser.new CSSLexer.new("batman")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "batman", f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttr
        p = CSSParser.new CSSLexer.new("the[joker]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "the", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["joker",nil,nil], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttrInList
        p = CSSParser.new CSSLexer.new("bruce[wayne~=awesome]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "bruce", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["wayne",:in_list,"awesome"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttrContains
        p = CSSParser.new CSSLexer.new("white[knight*=twoface]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "white", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["knight",:contains,"twoface"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttrMatches
        p = CSSParser.new CSSLexer.new("master[bruce/=hero]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "master", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["bruce",:matches,"hero"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttrBeginsWith
        p = CSSParser.new CSSLexer.new("the[story^=gordon]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "the", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["story",:begins_with,"gordon"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttrEndsWith
        p = CSSParser.new CSSLexer.new("the[film$=batpod]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "the", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["film",:ends_with,"batpod"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testAttrBeginsWithDash
        p = CSSParser.new CSSLexer.new("first[movie|=batman-begins]")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "first", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["movie",:begins_with_dash,"batman-begins"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testNoArgPseudoSelectors
        p = CSSParser.new CSSLexer.new(
            ":root:first-child:last-child:first-of-type:last-of-type:only-child" +
            ":only-of-type:empty:only-text")
        f = p.next
        assert_kind_of Token, f
        assert_equal :pseudo, f.type
        assert_equal ["root",nil], f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :pseudo, f.type
        assert_equal ["first-child",nil], f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :pseudo, f.type
        assert_equal ["last-child",nil], f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :pseudo, f.type
        assert_equal ["first-of-type",nil], f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :pseudo, f.type
        assert_equal ["last-of-type",nil], f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :pseudo, f.type
        assert_equal ["only-child",nil], f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :pseudo, f.type
        assert_equal ["only-of-type",nil], f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :pseudo, f.type
        assert_equal ["empty",nil], f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :pseudo, f.type
        assert_equal ["only-text",nil], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testIDClassSelectors
        p = CSSParser.new CSSLexer.new(".awesome#girl")
        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["class",:in_list,"awesome"], f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["id",:equal,"girl"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testCombinators
        p = CSSParser.new CSSLexer.new("one two + three>four   ~   five")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "one", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :descendant, f.type
        assert_equal nil, f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "two", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :neighbour, f.type
        assert_equal nil, f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "three", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :child, f.type
        assert_equal nil, f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "four", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :follower, f.type
        assert_equal nil, f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "five", f.value

        f = p.next
        assert_kind_of NilClass, f
    end
    
    def testAttrQuoted
        p = CSSParser.new CSSLexer.new("seven[children='gon\"e']")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "seven", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["children",:equal,"gon\"e"], f.value

        f = p.next
        assert_kind_of NilClass, f

        p = CSSParser.new CSSLexer.new('seven[children="go\\\"[]ne"]')
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "seven", f.value

        f = p.next
        assert_kind_of Token, f
        assert_equal :attribute, f.type
        assert_equal ["children",:equal,"go\"[]ne"], f.value

        f = p.next
        assert_kind_of NilClass, f
    end

    def testNthPseudo
        args = %w{2n+1 2n n+1 1 -2n+1 4n-1 -n-2 n-5 -3 -n}
        resps = [[2,1],[2,0],[1,1],[0,1],[-2,1],[4,-1],[-1,-2],[1,-5],[0,-3],[-1,0]]
        %w{child last-child of-type last-of-type}.each do |word|
            args.zip(resps).each do |(arg,response)|
                p = CSSParser.new CSSLexer.new(":nth-#{word}(#{arg})")
                f = p.next
                assert_kind_of Token, f
                assert_equal :pseudo, f.type
                assert_equal ["nth-#{word}",response], f.value

                f = p.next
                assert_kind_of NilClass, f
            end
        end
    end

    def testRestNil
        p = CSSParser.new CSSLexer.new("sand")
        f = p.next
        assert_kind_of Token, f
        assert_equal :element, f.type
        assert_equal "sand", f.value

        5.times {
            f = p.next
            assert_kind_of NilClass, f
        }
    end

    def testNot
        return
        args = ["element[attr]","not valid>stuff + you  ~  know",":root",":nth-child(2n+1)"]
        klasses = [[ElementSelector,AttributeSelector],nil,[RootSelector],[NthChildSelector]]

        args.zip(klasses).each do |(arg,kls)|
            p = CSSParser.new CSSLexer.new(":not(#{arg})")
            f = p.next
            assert_kind_of Token, f
            assert_equal :not, f.type

            if kls.nil?
                assert_kind_of NilClass, f.value
            else
                kls.each_with_index { |k,i|
                    assert_kind_of k, f.value[i]
                }
            end

            f = p.next
            assert_kind_of NilClass, f
        end
    end

end

