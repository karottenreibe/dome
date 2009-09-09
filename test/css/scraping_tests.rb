#!/usr/bin/env ruby
require 'test/unit'
require 'dome'

class SelectorTests < Test::Unit::TestCase
    include Dome
    include Selectors

    def setup
        @tree = Dome <<EOI
<root id=r1>
    <storage>
        <special value="CIA" />
        <data>1</data>
        <data>2</data>
        <data>3</data>
        <data>4</data>
        <data>5<x/>6<x/>7<x/>8<x/>9<x/>10</data>
    </storage>
    <storage>
        <data>11</data>
        <data>12</data>
        <data>13</data>
        <data>14</data>
        <data>15</data>
    </storage>
</root>
<root2 id=r2>
    <storage>
        <data>41</data>
        <data>42</data>
        <data>43</data>
        <data>44</data>
        <data>45</data>
    </storage>
    <storage>
        <data>51</data>
        <data>52</data>
        <data>53</data>
        <data>54</data>
        <data>55</data>
    </storage>
    <storage>
        <data>61</data>
        <data>62</data>
        <data>63</data>
        <special value="FBI" />
        <data>64</data>
        <data>65</data>
    </storage>
</root2>
EOI
    end

    def testElementScraping
        res = @tree.scrape do
            all "special ~ data", :element => :elems
            all "special ~ * ~ data", :element => :elems
        end

        assert_kind_of OpenHash, res
        assert_equal [:elems], res._keys
        assert_kind_of Array, res.elems
        res.elems.each { |elem|
            assert_kind_of Element, elem
            assert_equal :data, elem.tag
        }
        res = res.elems.collect { |e| e.children[0].value.to_i }
        assert_equal [1,64,2,65], res
    end

    def testAttributeScraping
        res = @tree.scrape do
            all "special", "@value" => :values
        end

        assert_kind_of OpenHash, res
        assert_equal [:values], res._keys
        assert_kind_of Array, res.values
        assert_equal ["CIA", "FBI"], res.values
    end

    def testDataScraping
        res = @tree.scrape do
            all "root > storage:first-child data:last-of-type", "$2" => :val
        end

        assert_kind_of OpenHash, res
        assert_equal [:val], res._keys
        assert_kind_of Array, res.val
        assert_equal ["6"], res.val

        res = @tree.scrape do
            all "root > storage:first-child data:last-of-type", "$2..4" => :val
        end

        assert_kind_of OpenHash, res
        assert_equal [:val], res._keys
        assert_kind_of Array, res.val
        assert_equal ["678"], res.val

        res2 = @tree.scrape do
            all "root > storage:first-child data:last-of-type", "$2...5" => :val
        end

        assert_equal res.to_h, res2.to_h
    end

    def testInnerOuterScraping
        %w{inner_html inner_text outer_html}.zip(
            [ ["1","64","2","65"],
              ["1","64","2","65"],
              ["<data>1</data>","<data>64</data>","<data>2</data>","<data>65</data>"]
            ]
        ).each { |(sel,data)|
            res = @tree.scrape do
                all "special ~ data", sel.to_sym => :elems
                all "special ~ * ~ data", sel.to_sym => :elems
            end

            assert_kind_of OpenHash, res
            assert_equal [:elems], res._keys
            assert_kind_of Array, res.elems
            res.elems.each { |elem| assert_kind_of String, elem }
            assert_equal data, res.elems
        }
    end

    def testTransformation
        res = @tree.scrape do
            all "root > storage:first-child data:not(:last-child)", :inner_text => :val
            result.val.map!(&:to_i)
        end

        assert_kind_of OpenHash, res
        assert_equal [:val], res._keys
        assert_kind_of Array, res.val
        assert_equal [1,2,3,4], res.val
    end

    def testFirst
        res = @tree.scrape do
            first "root > storage:first-child data:not(:last-child)", :inner_text => :val
            result.val = result.val.to_i
        end

        assert_kind_of OpenHash, res
        assert_equal [:val], res._keys
        assert_kind_of Integer, res.val
        assert_equal 1, res.val
    end

    def testNoSelector
        res = @tree.scrape do
            all "root > storage:first-child data:not(:last-child)", :val
            result.val.map!(&:inner_text).map!(&:to_i)
        end

        assert_kind_of OpenHash, res
        assert_equal [:val], res._keys
        assert_kind_of Array, res.val
        assert_equal [1,2,3,4], res.val
    end

end

