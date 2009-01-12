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

    include Spectre
    include Spectre::StringParsing

    ##
    # Keeps a single Document.
    # All the Nodes are accessible via the +root+ pseudo element's +children+
    # accessor or via the +roots+ Array.
    #
    class Document
        attr_accessor :roots, :root

        def initialize
            @root = Node.new
            @root.name = nil
        end

        def roots
            @root.children
        end

        def inspect
            "#<Dome::Document #{@root.inspect}"
        end
    end

    ##
    # Keeps a single Node of a Document with its +name+ (String), +attributes+ (Array) and
    # +children+ (Array).
    #
    class Node
        attr_accessor :name, :attributes, :children
        
        def initialize
            @name, @attributes, @children = '', [], []
        end

        def empty?
            @children.empty?
        end

        def inspect
            # first handle root case
            return "{ #{ @children.inject('') { |memo,c| memo + c.inspect } } }" if @name.nil?

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
    # Keeps text +data+.
    #
    class Data
        attr_accessor :data
        
        def initialize
            @data = ''
        end

        def inspect
            @data
        end
    end

    ##
    # Keeps a single Attribute of a Node with its +name+ and +value+.
    #
    class Attribute
        attr_accessor :name, :value

        def initialize
            @name, @value = '', ''
        end

        def inspect
            "#{@name}=#{@value.inspect}"
        end
    end

end

