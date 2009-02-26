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
                        case @op
                        when :equal then a.value == @value
                        when :in_list then a.value.split(/\s/).include? @value
                        when :contains then a.value.include? @value
                        when :ends_with then a.value.end_with? @value
                        when :begins_with then a.value.start_with? @value
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
                yield node if node.is_a? Element and  node.children.all? { |c| c.is_a? Data }
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

end

