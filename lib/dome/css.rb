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
# This file contains the CSS selector related classes and functions.
# It also extends the Tree class to provide CSS Selector functionality.
#

require 'dome/helpers/lexer'
require 'dome/helpers/css_parser'

module Dome

    ##
    # Enhances the Tree class with Hpricot-like functionality for using XPath.
    #
    class Tree
        def / path
        end

        def % path
        end

        def each path
        end
    end

    ##
    # Stores a list of CSS3 selectors over a Tree.
    # Can be used to iterate over all the Elements identified by the selectors
    # and to execute code for each found node.
    #
    class SelectorList

        ##
        # The selectors contained within this list.
        attr_accessor :selectors

        ##
        # Parses the given +string+ into a list of CSS3 selectors.
        #
        def initialize string
            @parser = CSSParser.new CSSLexer.new(string)
            parse
        end

        def each &block
            raise "SelectorList#each needs a block" unless block_given?
        end

        protected

        ##
        # Does the actual work of parsing the input into selectors.
        #
        def parse
        end

    end

    ##
    # Keeps the various selector classes.
    # Each selector has a +#walk+ method that expects an Element as its sole
    # parameter. It will apply the selector to that Element and yield the given
    # block for each matching element.
    #
    module Selectors

        class ElementSelector
            def initialize tag
                @tag = tag
            end

            def walk node
                yield node if @tag == :any or node.tag == @tag
            end
        end

        class AttributeSelector
            def initialize name, op, value
                @name, @op, @value = name, op, value
            end

            def walk node
                yield node if node.attributes.find { |a|
                    a.name == @name and
                        case op
                        when :equal then a.value == @value
                        when :in_list then a.value.split(/\s/).include? @value
                        when :contains then a.value.include? @value
                        when :ends_with then a.value.end_with? @value
                        when :begins_with then a.value.begin_with? @value
                        when :begins_with_dash
                            a.value == @value or a.value.begin_with "#{@value}-"
                        end
                }
            end
        end

        class ChildSelector
            def walk node
                node.children.each { |child|
                    yield child
                }
            end
        end

        class DescendantSelector
            def walk node
                node.children.each { |child|
                    yield child
                    walk child
                }
            end
        end

        class NeighbourSelector
            def walk node
                found = false
                node.parent.children.each { |child|
                    yield child if found
                    found = true if child == node
                }
            end
        end

        class FollowerSelector
            def walk node
                found = false
                node.children.each { |child|
                    yield child if found
                    found = false if found
                    found = true if child == node
                }
            end
        end

        class RootSelector
            def walk node
                yield node if node.root?
            end
        end

        class NthChildSelector
            def initialize args, reverse = false
                @args, @reverse = args, reverse
            end

            def walk node
                idx = node.parent.children.index node
                a,b = @args
                yield node if (a == 0 and b == idx) or a * ((idx-b)/a) + b == idx
            end
        end

        class NthOfTypeSelector
        end

        class OnlyChildSelector
        end

        class OnlyOfTypeSelector
        end

        class EmptySelector
        end

end
                        
