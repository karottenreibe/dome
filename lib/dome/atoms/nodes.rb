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

require 'dome/atoms/primitive'

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

        ##
        # Whether or not the Tree uses implicit namespace lookup.
        attr_accessor :implicit_namespaces

        def initialize
            @root = Root.new
            @root.tree = self
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

        ##
        # The Tree this Node belongs to - Tree
        attr_accessor :tree

        ##
        # Attaches this Node to the +p+ Element's children.
        #
        def parent= p
            raise "Nodes can only be attached to Elements or the Root" unless [Element,Root].include? p.class
            @parent = p
            @tree = p.tree
            p.children << self
        end

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
        # The Element's namespace - String or +nil+
        attr_accessor :namespace

        ##
        # The Element's tag - String
        attr_accessor :tag

        ##
        # The Element's attributes - Array of Attributes
        attr_accessor :attributes

        def namespace
            if @tree.implicit_namespaces
                self["xmlns:#{@namespace}"] || self[:xmlns] || (@parent ? @parent.namespace : nil)
            else @namespace
            end
        end

        ##
        # Initializes the Element's +tag+and +namespace+.
        #
        def initialize tag, namespace = nil
            super()
            @tag, @attributes, @namespace = tag, [], namespace
        end

        ##
        # Retrieves the first attribute, whose name is +key+, from the attributes hash, or +nil+ if
        # no such attribute was specified.
        #
        def [] key
            key = key.to_s.split ':'
            ns,key = key.length == 1 ? [nil,key[0].to_sym] : [key[0],key[1].to_sym]
            att = @attributes.find { |a| a.name == key and a.namespace == ns }
            att ||= @attributes.find { |a| a.name == key } if ns.nil?
            att ? att.value : nil
        end

        ##
        # Sets the attribute specified by +key+ to the given +value+ and creates such an Attribute
        # if it does not yet exist.
        #
        def []= key, value
            key = key.to_s.split ":"
            ns,key = key.length == 1 ? [nil,key[0].to_sym] : [key[0],key[1].to_sym]
            idx = @attributes.index { |a| a.name == key and a.namespace == ns }

            if idx then @attributes[idx].value = value
            else @attributes << Attribute.new(key, value, ns)
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
    # Keeps a single HTML Comment.
    #
    class Comment < Node

        ##
        # The text stored inside the Comment.
        #
        attr_accessor :text

        def initialize text
            @text = text
        end

        def inner_html
            "<!--#{@text}-->"
        end

        alias_method :outer_html, :inner_html
        alias_method :to_s, :inner_html

        def inspect
            inner_html.inspect
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
            super()
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
    class Attribute < Node

        ##
        # The Attribute's namespace - String or +nil+
        attr_accessor :namespace

        ##
        # The name that identifies the Attribute.
        #
        attr_accessor :name

        ##
        # The value associated with the Attribute's name.
        # May be +nil+, if no value was specified.
        #
        attr_accessor :value

        ##
        # Attaches this attribute to the +p+ Element.
        #
        def parent= p
            raise "Attributes can only be attached to Elements" unless p.is_a? Element
            @parent = p
            @tree = p.tree
            p.attributes << self
        end

        ##
        # Initializes the Attribute's +name+, +value+ and +namespace+.
        # +name+ must be convertible to a Symbol.
        #
        def initialize name, value = nil, namespace = nil
            super()
            @name, @value, @namespace = name.to_sym, value, namespace
        end

        def inspect
            @value ? "#{@name}='#{ @value.gsub("'", "\\\\'") }'" : @name.to_s
        end

        alias_method :to_s, :inspect
        alias_method :inner_html, :inspect
        alias_method :outer_html, :inspect

    end

end

