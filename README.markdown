# Dome #

This is [Dome], a pure Ruby HTML DOM parser with CSS3 support.

## Features ##

Dome features a **HTML DOM parser** (i.e. it generate a tree structure
from the HTML document) that supports common HTML/XML including
namespaces and HTML comments. It is designed to never abort parsing
due to errors and will instead try to fix the errors.

It also features an implementation of **CSS3 selectors** to traverse a
DOM tree and grab elements from it, although it [diverges a bit] [cssdiv]
from the standard in some points.

Furthermore it has a **Scraper** class that allows for easy extraction of
arbitrary data from HTML documents with very little code overhead.

## Usage ##

    require 'rubygems'
    require 'openuri'
    require 'dome'

    document = open('http://www.google.com/search?q=ruby') { |file| file.read }
    tree = Dome(document)
    puts tree.root.children[0].tag

    header  = tree % 'div#header'

    results = tree / '#res ol > li > h3'
    results.map! { |h3| h3.inner_text }

    scraped = tree.scrape do
        first '#header', :results
        all '#res ol > li > h3', :inner_text => :results
    end

    assert_kind_of  OpenHash, scraped
    assert_equal    header,   scraped.header
    assert_equal    results,  scraped.results

## License ##

    Copyright (c) 2009 Fabian Streitel

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use,
    copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following
    conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.


[dome]:     http://wiki.github.com/karottenreibe/dome/      "Dome's homepage"
[cssdiv]:   

