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

    class ElementSelector
        def initialize tag
            @tag = tag
        end

        def walk node
            node.children.each { |child|
                yield child if child.tag == @tag
            }
        end
    end

    class AttributeSelector
        def initialize name, value
            @name, @value = name, value
        end

        def walk node
            node.children.each { |child|
                yield child if child.attributes.find { |a|
                    a.name == @name and ( @value.nil? or a.value == @value )
                }
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
            @mult, @offset, @reverse = args[0], args[1], reverse
        end

        def walk node
            group = @reverse ? node.children.reverse : node.children
            n = 0
            group.each_with_index { |child,i|
                if i == @mult * n + @offset
                    n += 1
                    yield child
                    #TODO: really working?
                end
            }
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
                        
