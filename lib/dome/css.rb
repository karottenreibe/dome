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
# This file contains the CSS Selector related classes and functions.
# It also extends the Tree class to provide CSS Selector functionality.
#

require 'dome/helpers/lexer'
require 'dome/helpers/css_parser'

module Dome

    ##
    # Enhances the Tree class with Hpricot-like functionality for using CSS Selectors.
    #
    class Tree

        ##
        # Extracts all Elements matching the given CSS3 +path+.
        #
        def / path
            ret = []
            SelectorList.new(path).each(self) { |node| ret << node }
            ret
        end

        ##
        # Extracts the first Element matching the given CSS3 +path+.
        #
        def % path
            callcc { |cc|
                SelectorList.new(path).each(self) { |node| cc.call node }
            }
        end

        ##
        # Executes the given block for each Element matching the given CSS3 +path+.
        #
        def each path
            raise "Tree#each expects a block" unless block_given?
            ret = []
            SelectorList.new(path).each(self) { |node| yield node }
            ret
        end

    end

    ##
    # Keeps the various Selector classes.
    # Each Selector has a +#walk+ method that expects an Element as its sole
    # parameter. It will apply the Selector to that Element and yield the given
    # block for each matching element.
    #
    module Selectors

        class ElementSelector 
            def initialize tag
                @tag = tag
            end

            def walk node
                yield node if node.is_a? Element and @tag == :any or node.tag == @tag
            end
        end

        class AttributeSelector
            def initialize name, op, value
                @name, @op, @value = name, op, value
            end

            def walk node
                yield node if node.is_a? Element and node.attributes.find { |a|
                    a.name == @name and
                        case op
                        when :equal then a.value == @value
                        when :in_list then a.value.split(/\s/).include? @value
                        when :contains then a.value.include? @value
                        when :ends_with then a.value.end_with? @value
                        when :begins_with then a.value.begin_with? @value
                        when :begins_with_dash
                            a.value == @value or a.value.begin_with "#{@value}-"
                        else true
                        end
                }
            end
        end

        class ChildSelector
            def walk node
                node.children.each { |child|
                    yield child if child.is_a? Element
                }
            end
        end

        class DescendantSelector
            def walk node
                node.children.each { |child|
                    yield child if child.is_a? Element
                    walk child
                }
            end
        end

        class NeighbourSelector
            def walk node
                found = false
                node.parent.children.each { |child|
                    yield child if found and child.is_a? Element
                    found = true if child == node
                }
            end
        end

        class FollowerSelector
            def walk node
                found = false
                node.children.each { |child|
                    if child.is_a? Element and found
                        yield child
                        found = false
                    end
                    found = true if child == node
                }
            end
        end

        class RootSelector
            def walk node
                yield node if node.is_a? Element and node.parent.root?
            end
        end

        class NthChildSelector
            def initialize args, reverse
                @args, @reverse = args, reverse
            end

            def walk node
                nth_walk( @reverse ? node.parent.children.reverse : node.parent.children )
            end

            protected

            def nth_walk group
                idx = group.index node
                a,b = @args
                yield node if node.is_a? Element and
                    (a == 0 and b == idx) or a * ((idx-b)/a) + b == idx
            end
        end

        class NthOfTypeSelector < NthChildSelector
            def initialize args, reverse, tag
                @tag = tag
                super(args, reverse)
            end

            protected

            def nth_walk group
                group = group.find_all { |item|
                    item.is_a? Element and (@tag == :any or item.tag == @tag)
                }
                super(group)
            end
        end

        class OnlyChildSelector
            def walk node
                yield node if node.is_a? Element and node.parent.children.length == 1
            end
        end

        class OnlyOfTypeSelector
            def initialize tag
                @tag = tag
            end

            def walk node
                yield node if node.is_a? Element and node.parent.children.find_all { |c|
                    c.is_a? Element and (@tag == :any or c.tag == @tag)
                }.length == 1
            end
        end

        class EmptySelector
            def walk node
                yield node if node.is_a? Element and node.children.empty?
            end
        end

        class OnlyTextSelector
            def walk node
                yield node if node.is_a? Element and node.children.find_all { |c| not c.is_a? Data }.empty?
            end
        end

        class NotSelector
            def initialize slist
                @slist = slist
            end

            def walk node
                yield node unless callcc do |cc|
                    @slist.each(node) { cc.call true }
                end
            end
        end

    end

    ##
    # Stores a list of CSS3 Selectors over a Tree.
    # Can be used to iterate over all the Elements identified by the Selectors
    # and to execute code for each found node.
    #
    class SelectorList

        include Dome::Selectors

        ##
        # The Selectors contained within this list.
        attr_accessor :selectors

        ##
        # Parses the given +string+ into a list of CSS3 Selectors.
        #
        def initialize string
            @selectors = []
            @parser = CSSParser.new CSSLexer.new(string)
            parse
        end

        ##
        # Executes the given +block+ for each node in the Tree given in +obj+ - or constructed
        # from +obj+ in case +obj+ is an Element - that matches this SelectorList.
        #
        def each obj, &block
            raise "SelectorList#each expects either a Tree or an Element as first argument" unless
                [Tree, Element].include? obj.class
            raise "SelectorList#each expects a block" unless block_given?
            return if @selectors.empty?

            if obj.is_a? Element
                t = Tree.new
                t.root.children << obj
                obj = t
            end

            nodes = nil
            sels = nil
            case @selectors[0]
            when RootSelector
                if obj.is_a? Tree then nodes = obj.root.children
                else nodes = [obj]
                end

                sels = @selectors[1..-1]
            else
                if obj.is_a? Tree then nodes = obj.flatten
                else
                    t = Tree.new
                    t.root.children << obj
                    nodes = t.flatten
                end

                sels = @selectors
            end

            sels.each do |sel|
                new_nodes = []

                nodes.each { |node|
                    sel.walk(node) { |ret| new_nodes << ret }
                }

                nodes = new_nodes
            end

            nodes.each { |node| block.call node }
            nil
        end

        protected

        ##
        # Does the actual work of parsing the input into Selectors.
        #
        def parse
            last_elem = :any

            while t = @parser.next
                case t.type
                when :element
                    @selectors << ElementSelector.new(t.value)
                    last_elem = t.value
                when :attribute
                    @selectors << AttributeSelector.new(*t.value)
                when :pseudo
                    @selectors <<
                        case t.value[0]
                        when "not" then NotSelector.new(t.value[1])
                        when "root" then RootSelector.new

                        when "nth-child" then NthChildSelector.new(t.value[1], false)
                        when "nth-last-child" then NthChildSelector.new(t.value[1], true)
                        when "first-child" then NthChildSelector.new([0,1], false)
                        when "last-child" then NthChildSelector.new([0,1], true)

                        when "nth-of-type" then NthOfTypeSelector.new(t.value[1], false, last_elem)
                        when "nth-last-of-type" then NthOfTypeSelector.new(t.value[1], true, last_elem)
                        when "first-of-type" then NthOfTypeSelector.new([0,1], false, last_elem)
                        when "last-of-type" then NthOfTypeSelector.new([0,1], true, last_elem)

                        when "only-child" then OnlyChildSelector.new
                        when "only-of-type" then OnlyOfTypeSelector.new(last_elem)
                        when "empty" then EmptySelector.new
                        when "only-text" then OnlyTextSelector.new
                        end
                when :child
                    @selectors << ChildSelector.new
                    last_elem = :any
                when :descendant
                    @selectors << DescendantSelector.new
                    last_elem = :any
                when :follower
                    @selectors << FollowerSelector.new
                    last_elem = :any
                when :neighbour
                    @selectors << NeighbourSelector.new
                    last_elem = :any
                when :tail
                    @selectors = []
                end
            end
        end

    end

end

