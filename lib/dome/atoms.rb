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
# Contains the atomic objects that compose a DOM tree.
#

require 'dome/helpers/primitive'

module Dome

    ##
    # Keeps a single Tree.
    # All the Elements are accessible via the +root+ pseudo element's +children+
    # accessor.
    #
    class Tree

        ##
        # The root pseudo Node.
        attr_accessor :root

        def initialize
            @root = Root.new
        end

        ##
        # Returns a list of all Elements in this Tree.
        # The pseudo root Element is not included.
        #
        def flatten
            @root.children.collect { |r|
                r.respond_to?(:flatten) ? r.flatten : []
            }.flatten
        end

        def inspect
            "#<Dome::Tree #{@root.inspect}"
        end

    end

    ##
    # The base class for all other classes living in the Tree.
    #
    class Node

        ##
        # The Node's children - Array
        attr_accessor :children

        ##
        # The Node's parent - Node
        attr_accessor :parent

        def initialize
            @children = []
        end

        ##
        # Whether or not the Node has children.
        #
        def empty?
            @children.empty?
        end

        ##
        # Whether or not the Node is the root pseudo Node.
        #
        def root?
            is_a? Root
        end

        def to_s
            outer_html
        end

    end

    ##
    # The class of the pseudo root Node.
    #
    class Root < Node
        def inner_html
            @children.inject("") { |memo,c| memo + c.outer_html }
        end

        alias_method :outer_html, :inner_html

        def inspect
            @children.inspect
        end
    end

    ##
    # Keeps a single Element of a Tree with its +tag+, +attributes+ and +children+.
    #
    class Element < Node

        ##
        # The Element's tag - String
        attr_accessor :tag

        ##
        # The Element's attributes - Array of Attributes
        attr_accessor :attributes

        def initialize tag = "", parent = nil
            super()
            @tag, @attributes, @parent = tag, [], parent
        end

        ##
        # Retrieves the attribute specified by +key+ from the attributes hash, or +nil+ if
        # no such attribute was specified.
        # The +key+ must be convertible to a String.
        #
        def [] key
            key = key.to_s
            att = @attributes.find { |a| a.name == key }
            att ? att.value : nil
        end

        ##
        # Sets the attribute specified by +key+ to the given +value+ and creates such an Attribute
        # if it does not yet exist.
        # The +key+ must be convertible to a String.
        #
        def []= key, value
            key = key.to_s
            idx = @attributes.index { |a| a.name == key }

            if idx then @attributes[idx].value = value
            else @attributes << Attribute.new(key, value)
            end
        end

        ##
        # Returns an Array containing this Element and all its in/direct children.
        #
        def flatten
            @children.collect { |c|
                c.respond_to?(:flatten) ? c.flatten : []
            }.flatten.unshift(self)
        end

        ##
        # Retrieves the HTML representation of this Element and all its descendants.
        # Actually just an alias for +#inspect+.
        #
        def outer_html
            empty? ? inspect : start_tag + inner_html + end_tag
        end

        ##
        # Retrieves the HTML representation of all the descendants of this Element.
        #
        def inner_html
            @children.inject('') { |memo,c| memo + c.outer_html }
        end

        ##
        # Retrieves the text representation of all the Data Nodes that reside under this
        # Element in the Tree.
        #
        def inner_text
            @children.inject('') do |memo,c|
                memo +
                    case c
                    when Element then c.inner_text
                    else c.value
                    end
            end
        end

        ##
        # Returns a String representation of the start tag of the Element.
        #
        def start_tag
            ret = "<#{@tag}"
            ret += @attributes.inject(' ') { |memo,a| "#{memo} #{a.inspect}" } unless @attributes.empty?
            ret + ">"
        end

        ##
        # Returns a String representation of the end tag of the Element.
        #
        def end_tag
            "</#{@tag}>"
        end

        def inspect
            start_tag + (
                empty? ?
                '/>' :
                "#{ @children.inject('') { |memo,c| "#{memo} #{c.inspect}" } } #{end_tag}"
            )
        end

    end

    ##
    # Keeps text data, either normally or as a CDATA section.
    #
    class Data < Node

        ##
        # The data enclosed in this object - String
        attr_accessor :value

        ##
        # Whether or not the data is enclosed in a CDATA section.
        #
        def cdata?
            @cdata
        end
        
        def initialize value = '', cdata = false
            @value, @cdata = value, cdata
        end

        def inspect
            inner_html.inspect
        end

        def inner_html
            @cdata ? "<![CDATA[#{ @value }]]>" : @value
        end

        alias_method :outer_html, :inner_html

    end

    ##
    # Keeps a single Element Attribute.
    # NOTE: It's value may be +nil+.
    #
    # = Why don't we use Hashes? =
    #
    # Because there could be stuff like:
    #
    #   <a href="foo" href="bar">...
    #
    # And we'd like to let the user decide how to handle this.
    #
    primitive :Attribute, [:name, :value] do
        def inspect
            @value ? "#{@name}='#{ @value.gsub("'", "\\\\'") }'" : @name
        end
    end

end

