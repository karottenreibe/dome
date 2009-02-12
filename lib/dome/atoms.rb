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
#               or read the file LICENSE distributed with this software.
# Homepage::    http://dome.rubyforge.org/
# Git repo::    http://rubyforge.org/scm/?group_id=7589
#
# Contains the atomic objects that compose a document tree.
#

module Dome

    ##
    # Keeps a single Document.
    # All the Elements are accessible via the +root+ pseudo element's +children+
    # accessor.
    #
    class Document
        ##
        # The root pseudo Element.
        attr_accessor :root

        def initialize
            @root = Element.new
            @root.tag = nil
        end

        def inspect
            "#<Dome::Document #{@root.inspect}"
        end
    end

    ##
    # Keeps a single Element of a Document with its +tag+, +attributes+ and +children+.
    #
    class Element
        ##
        # The Element's tag - String
        attr_accessor :tag

        ##
        # The Element's attributes - Hash: String => String
        attr_accessor :attributes

        ##
        # The Element's children - Array
        attr_accessor :children

        ##
        # The Element's parent - Element
        attr_accessor :parent
        
        def initialize name = "", attributes = {}, children = []
            @name, @attributes, @children = name, attributes, children
        end

        ##
        # Whether or not the Element has children.
        #
        def empty?
            @children.empty?
        end

        ##
        # Whether or not the Element is the root pseudo Element.
        #
        def root?
            @tag.nil?
        end

        ##
        # Retrieves the attribute specified by +key+ from the attributes hash, or +nil+ if
        # no such attribute was specified.
        #
        def [] key
            @attributes[key]
        end

        def inspect
            # first handle root case
            return "{ #{ @children.inject('') { |memo,c| memo + c.inspect } } }" if self.root?

            ret = "<#{@name}"
            ret += @attributes.inject(' ') { |memo,a| "#{memo} #{a.inspect}" } unless @attributes.empty?

            if empty?
                ret += '/>'
            else
                ret += ">#{ @children.inject('') { |memo,c| memo + c.inspect } }</#{@name}>"
            end

            ret
        end
    end

    ##
    # Keeps text data, either normally or as a CDATA section.
    #
    class Data
        ##
        # The data enclosed in this object - String
        attr_accessor :value

        ##
        # Whether or not the data is enclosed in a CDATA section - Boolean
        attr_accessor :cdata
        
        def initialize value = '', cdata = false
            @value, @cdata = value, cdata
        end

        def inspect
            @cdata ? "<[CDATA[#{@data}]]>" : @data
        end
    end

end

