#
# This file contains the CSS Selector related classes and functions.
# It also extends the Tree class to provide CSS Selector functionality.
#

module Dome

    ##
    # Keeps the various Selector classes.
    # Each Selector has a +#walk+ method that expects an Element as its sole
    # parameter. It will apply the Selector to that Element and yield the given
    # block for each matching element.
    #
    module Selectors

        class ElementSelector 
            def initialize( tag )
                @tag = tag
            end

            def walk( node )
                yield node if  node.is_a?(Element) \
                           and (@tag == :any or node.tag == @tag.to_sym)
            end

            def inspect; @tag; end
        end

        class AttributeSelector
            def initialize( ns, name, op, value )
                @ns, @name, @op, @value = ns, name.to_sym, op, value
            end

            def walk( node )
                yield node if node.is_a?(Element) and node.attributes.find { |a|
                    a.name == @name and
                        (@ns == :any or a.namespace == @ns or (not @ns.nil? and a.namespace == @ns.to_sym)) and
                        case @op
                        when :equal       then a.value == @value
                        when :in_list     then a.value.split(/\s/).include?(@value)
                        when :contains    then a.value.include?(@value)
                        when :ends_with   then a.value.end_with?(@value)
                        when :begins_with then a.value.start_with?(@value)
                        when :begins_with_dash
                            a.value == @value or a.value.begin_with("#{@value}-")
                        when :matches     then Regexp.new(@value) =~ a.value
                        else true
                        end
                }
            end

            def inspect
                table = { :equal            => '=',
                          :in_list          => '~=',
                          :contains         => '*=',
                          :ends_with        => '$=',
                          :begins_with      => '^=',
                          :begins_with_dash => '|=',
                          :matches          => '/=' }

                "[#{
                    case @ns
                    when nil  then '|'
                    when :any then ''
                    else @ns + '|'
                    end
                }#{@name}#{ @op ? table[@op] + @value.inspect : '' }]"
            end
        end

        class NamespaceSelector 
            def initialize( ns )
                @ns = ns
            end

            def walk( node )
                yield node if  node.is_a?(Element) \
                           and (@ns == :any or  node.namespace == @ns \
                                or (not @ns.nil? and node.namespace == @ns.to_sym))
            end

            def inspect
                case @ns
                when nil  then '|'
                when :any then '*|'
                else "#{@ns}|"
                end
            end
        end

        class ChildSelector
            def walk( node )
                node.children.each { |child|
                    yield(child) if child.is_a?(Element)
                }
            end

            def inspect; " > "; end
        end

        class DescendantSelector
            def walk( node, &block )
                node.children.each { |child|
                    yield(child)        if child.is_a?(Element)
                    walk(child, &block) if child.is_a?(Element)
                }
            end

            def inspect; " "; end
        end

        class ReverseNeighbourSelector
            def walk( node )
                idx = node.parent.children.index(node) - 1

                idx.downto(0) do |i|
                    child = node.parent.children[i]
                    yield(child) if child.is_a?(Element)
                end
            end

            def inspect; " < "; end
        end

        class NeighbourSelector
            def walk( node )
                idx = node.parent.children.index(node) + 1

                idx.upto(node.parent.children.length-1) do |i|
                    child = node.parent.children[i]
                    yield(child) if child.is_a?(Element)
                end
            end

            def inspect; " + "; end
        end

        class PredecessorSelector
            def walk( node )
                idx = node.parent.children.index(node) - 1

                idx.downto(0) do |i|
                    child = node.parent.children[i]
                    return yield(child) if child.is_a?(Element)
                end
            end

            def inspect; " % "; end
        end

        class FollowerSelector
            def walk( node )
                idx = node.parent.children.index(node) + 1

                idx.upto(node.parent.children.length-1) do |i|
                    child = node.parent.children[i]
                    return yield(child) if child.is_a?(Element)
                end
            end

            def inspect; " ~ "; end
        end

        class RootSelector
            def walk( node )
                yield node if node.is_a?(Element) and node.parent.root?
            end

            def inspect; ":root"; end
        end

        class NthChildSelector
            def initialize( args, reverse )
                @args, @reverse = args, reverse
            end

            def walk( node, &block )
                group = node.parent.children.find_all { |n| n.is_a?(Element) }
                group.reverse! if @reverse
                nth_walk(group, node, &block)
            end

            def inspect
                ":nth-child(#{self.nth_inspect})"
            end

            protected

            def nth_walk( group, node )
                idx = group.index(node) + 1
                a,b = @args
                yield node if  node.is_a?(Element) \
                           and (a == 0 and b               == idx) \
                           or  (a != 0 and a*((idx-b)/a)+b == idx)
            end

            def nth_inspect
                a,b = @args
                if    a == 2 and b == 0 then "even"
                elsif a == 2 and b == 1 then "odd"
                elsif a == 0            then b.to_s
                elsif a == 1 and b == 0 then "n"
                elsif a == 1            then "n+#{b}"
                elsif b == 0            then "#{a}n"
                else                         "#{a}n+#{b}"
                end
            end

        end

        class NthOfTypeSelector < NthChildSelector
            def initialize( args, reverse, tag )
                @tag = tag
                super(args, reverse)
            end

            def inspect
                ":nth-of-type(#{self.nth_inspect})"
            end

            protected

            def nth_walk( group, node, &block )
                return if @tag != :any and @tag.to_sym != node.tag
                group = group.find_all { |item|
                    tag = @tag == :any ? node.tag : @tag.to_sym
                    item.tag == tag
                }
                super(group, node, &block)
            end

        end

        class OnlyChildSelector
            def walk( node )
                yield(node) if node.is_a?(Element) and node.parent.children.length == 1
            end

            def inspect; ":only-child"; end
        end

        class OnlyOfTypeSelector
            def initialize( tag )
                @tag = tag
            end

            def walk( node )
                yield(node) if node.is_a?(Element) and node.parent.children.find_all { |c|
                    c.is_a?(Element) and (@tag == :any or c.tag == @tag.to_sym)
                }.length == 1
            end

            def inspect; ":only-of-type"; end
        end

        class EmptySelector
            def walk( node )
                yield(node) if node.is_a?(Element) and node.children.empty?
            end

            def inspect; ":empty"; end
        end

        class OnlyTextSelector
            def walk( node )
                yield(node) if node.is_a?(Element) and not node.empty? and
                    node.children.all? { |c| c.is_a?(Data) }
            end

            def inspect; ":only-text"; end
        end

        class NotSelector
            def initialize( slist )
                @slist = slist
            end

            def walk( node )
                yield node if node.is_a?(Element) and not @slist.first(node)
            end

            def inspect; ":not(#{@slist.internal_inspect})"; end
        end

        class EpsilonSelector
            def initialize( slist )
                @slist = slist
            end

            def walk( node )
                yield(node) if node.is_a?(Element) and @slist.first(node)
            end

            def inspect; ":eps(#{@slist.internal_inspect})"; end
        end

        class ParentSelector
            def walk( node )
                yield node.parent unless node.parent.root?
            end

            def inspect; ".."; end
        end

    end

end

