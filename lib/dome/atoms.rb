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
        # Whether or not the Node has children.
        #
        def empty?
            @children.empty?
        end

        ##
        # Whether or not the Node is the root pseudo Node.
        #
        def root?; false; end

    end

    ##
    # The class of the pseudo root Node.
    #
    class Root < Node
        def root?; true; end

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

        def initialize tag = "", parent = nil, attributes = [], children = []
            @tag, @attributes, @children, @parent = tag, attributes, children, parent
        end

        ##
        # Retrieves the attribute specified by +key+ from the attributes hash, or +nil+ if
        # no such attribute was specified.
        #
        def [] key
            @attributes[key]
        end

        def inspect
            ret = "<#{ @name }"
            ret += @attributes.inject(' ') { |memo,a| "#{memo} #{a.inspect}" } unless @attributes.empty?

            if empty?
                ret += '/>'
            else
                ret += ">#{ @children.inject('') { |memo,c| memo + c.inspect } }</#{ @name }>"
            end

            ret
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
            @cdata ? "<[CDATA[#{ @value }]]>" : @value.to_s
        end
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

