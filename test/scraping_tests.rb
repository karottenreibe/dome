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
require 'lib/dome/scraper'

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
        <data>5</data>
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
        p (@tree/"special ~ * ~ *").collect { |x| x.tag }
        return

        res = @tree.scrape do
            all "special ~ data"
            scrape :element => :elems

            all "special ~ * ~ data"
            scrape :element => :elems
        end

        assert_kind_of Hash, res
        assert_equal [:elems], res.keys
        assert_kind_of Array, res[:elems]
        res[:elems].each { |elem|
            assert_kind_of Element, elem
            assert_equal "data", elem.tag
        }
        res = res[:elems].collect { |e| e.children[0].value.to_i }
        assert_equal [1,64,2,65], res
    end

end

