#
# This file contains the CSS Selector related classes and functions.
# It also extends the Tree class to provide CSS Selector functionality.
#

require 'dome/parsing/css_lexer'
require 'dome/parsing/css_parser'
require 'dome/atoms/selectors'

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
            sel = path.is_a?(Selector) ? path : Selector.new(path)
            sel.each(self) { |node| ret << node }
            ret
        end

        ##
        # Extracts the first Element matching the given CSS3 +path+.
        #
        def % path
            sel = path.is_a?(Selector) ? path : Selector.new(path)
            sel.first self
        end

        ##
        # Executes the given block for each Element matching the given CSS3 +path+.
        #
        def each path
            raise "Tree#each expects a block" unless block_given?
            ret = []
            sel = path.is_a?(Selector) ? path : Selector.new(path)
            sel.each(self) { |node| yield node }
            ret
        end

    end

    ##
    # The exception raised when parsing of a CSS selector fails.
    #
    class CSSParsingError < RuntimeError

        ##
        # Description of what failed to parse.
        #
        attr_accessor :what

        ##
        # Description of the location of the error within the input string.
        #
        attr_accessor :where

        def initialize what, where
            @what, @where = what, where
        end

        def to_s
            "failed to parse #{@what} at #{@where}"
        end
    end

    ##
    # Stores a list of CSS3 Selectors over a Tree.
    # Can be used to iterate over all the Elements identified by the Selectors
    # and to execute code for each found node.
    #
    class Selector

        include Dome::Selectors

        ##
        # The Selectors contained within this list.
        attr_accessor :selectors

        ##
        # May contain an additional Selector that will be or'ed together with this
        # one - Selector or +nil+
        attr_accessor :or

        ##
        # Parses the given +obj+ (String or Lexer) into a list of CSS3 Selectors.
        #
        def initialize obj
            obj = CSSLexer.new(obj) unless obj.is_a? Lexer
            @selectors, @or = [], nil
            @parser = CSSParser.new obj
            parse
            @parser = nil
        end

        ##
        # Executes the given +block+ for each Node in the Tree given in +obj+ - or constructed
        # from +obj+ in case +obj+ is an Element or an Array of Elements - that matches this
        # Selector.
        #
        def each obj, &block
            raise "Selector#each expects any of [Tree, Element, Array of Elements] as first argument" unless
                [Tree, Element].include? obj.class or ( obj.is_a? Array and obj.all? { |n| n.is_a? Element } )
            raise "Selector#each expects a block" unless block_given?
            return if @selectors.empty?

            nodes = sels = nil
            if obj.is_a? Tree
                if @selectors[0].is_a? RootSelector
                    nodes = obj.root.children.find_all { |r| r.is_a? Element }
                    sels = @selectors[1..-1]
                else
                    nodes = obj.flatten
                    sels = @selectors
                end
            else
                nodes = [obj].flatten
                sels = @selectors
            end

            sels.each do |sel|
                new_nodes = []

                nodes.each { |node|
                    sel.walk(node) { |ret| new_nodes << ret unless new_nodes.include? ret }
                }

                return if new_nodes.empty?
                nodes = new_nodes
            end

            nodes.each { |node| block.call node }

            @or.each obj, &block if @or

            nil
        end

        ##
        # Returns the first Node in the Tree given in +obj+ - or constructed from +obj+ in case +obj+
        # is an Element or an Array of Elements - that matches this Selector -- or +nil+ if none is found.
        #
        def first obj
            raise "Selector#first expects any of [Tree, Element, Array of Elements] as first argument" unless
                [Tree, Element].include? obj.class or ( obj.is_a? Array and obj.all? { |n| n.is_a? Element } )
            return if @selectors.empty?

            nodes = sels = nil
            if obj.is_a? Tree
                if @selectors[0].is_a? RootSelector
                    nodes = obj.root.children.find_all { |r| r.is_a? Element }
                    sels = @selectors[1..-1]
                else
                    nodes = obj.flatten
                    sels = @selectors
                end
            else
                nodes = [obj].flatten
                sels = @selectors
            end
 
            levels = [nodes]
          
            while not levels.empty?
                # we're done if the last selector has been applied and something
                # was found
                return levels[-1][0] if levels.length == sels.length+1

                # if the last level is empty, we're done there
                while levels[-1].empty?
                    levels.delete_at -1
                    # abort condition in case no element was found at all
                    return nil if levels.empty?
                end

                # generate a new level from the first node in the last level
                node = levels[-1].delete_at 0
                lvl = []
                sels[levels.length-1].walk(node) { |ret| lvl << ret }
                levels << lvl unless lvl.empty?
            end

            nil
        end

        def inspect
            "#<Dome::Selector {#{internal_inspect}}>"
        end

        def internal_inspect
            @selectors.inject('') { |memo,s| memo + s.inspect }
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
                when :namespace
                    @selectors << NamespaceSelector.new(t.value)
                when :parent
                    @selectors << ParentSelector.new
                when :pseudo
                    @selectors <<
                        case t.value[0]
                        when :not then NotSelector.new(t.value[1])
                        when :eps then EpsilonSelector.new(t.value[1])
                        when :root then RootSelector.new

                        when :"nth-child" then NthChildSelector.new(t.value[1], false)
                        when :"nth-last-child" then NthChildSelector.new(t.value[1], true)
                        when :"first-child" then NthChildSelector.new([0,1], false)
                        when :"last-child" then NthChildSelector.new([0,1], true)

                        when :"nth-of-type" then NthOfTypeSelector.new(t.value[1], false, last_elem)
                        when :"nth-last-of-type" then NthOfTypeSelector.new(t.value[1], true, last_elem)
                        when :"first-of-type" then NthOfTypeSelector.new([0,1], false, last_elem)
                        when :"last-of-type" then NthOfTypeSelector.new([0,1], true, last_elem)

                        when :"only-child" then OnlyChildSelector.new
                        when :"only-of-type" then OnlyOfTypeSelector.new(last_elem)
                        when :empty then EmptySelector.new
                        when :"only-text" then OnlyTextSelector.new
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
                when :predecessor
                    @selectors << PredecessorSelector.new
                    last_elem = :any
                when :reverse_neighbour
                    @selectors << ReverseNeighbourSelector.new
                    last_elem = :any
                when :neighbour
                    @selectors << NeighbourSelector.new
                    last_elem = :any
                when :or then @or = t.value
                when :tail
                    raise CSSParsingError.new(@parser.last_failure[:what], @parser.last_failure[:descriptive])
                end
            end
        end

    end

end

