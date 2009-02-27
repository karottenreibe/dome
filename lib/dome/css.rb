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
require 'dome/selectors'

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

            nodes = obj.flatten.find_all { |n| n.is_a? Element }

            @selectors.each do |sel|
                new_nodes = []

                nodes.each { |node|
                    sel.walk(node) { |ret| new_nodes << ret unless new_nodes.include? ret }
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

