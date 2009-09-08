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

    document = open('http://www.google.de') { |file| file.read }
    tree = Dome(document)
    puts tree.root.children[0].tag

    divs = tree / 'div'

## License ##

/*---- DON'T PANIC License 1.1 -----------

  Don't panic, this piece of software is
  free, i.e. you can do with it whatever
  you like, including, but not limited to:
  
    * using it
    * copying it
    * (re)distributing it
    * burning/burying/shredding it
    * eating it
    * using it to obtain world domination
    * and ignoring it
  
  Under the sole condition that you
  
    * CONSIDER buying the author a strong
      brownian motion producer, say a nice
      hot cup of tea, should you ever meet
      him in person.

----------------------------------------*/


[dome]:     http://wiki.github.com/karottenreibe/dome/      "Dome's homepage"
[cssdiv]:   

