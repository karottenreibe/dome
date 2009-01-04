# This is Dome, a pure Ruby HTML DOM parser with very simple XPath support.
#
# If you want to find out more or need a tutorial, go to
# http://dome.rubyforge.org/
# You'll find a nice wiki there!
#
# Author::      Fabian Streitel (karottenreibe)
# Copyright::   Copyright (c) 2008 Fabian Streitel
# License::     Creative Commons Attribution 3.0 Germany
#               For further information regarding this license, you can go to
#               http://creativecommons.org/licenses/by/3.0/de/
# Homepage::    http://dome.rubyforge.org/
# Git repo::    http://rubyforge.org/scm/?group_id=
#

module Dome

    ##
    # Keeps a single Document.
    #
    class Document
        attr_accessor :roots

        def initialize
            @roots = []
        end

        def inspect
            "#<Dome::Document @roots=[" +
            "#{ @roots.inject(nil) { |memo,n| memo ? "#{memo}, #{n.inspect}" : n.inspect } }]>"
        end
    end

    ##
    # Keeps a single Node of a Document.
    #
    class Node
        attr_accessor :name, :attributes, :children
        
        def initialize
            @name, @attributes, @children = '', [], []
        end

        def inspect
            "<#{@name} " +
            "#{ @attributes.inject('') { |memo,a| "#{memo} #{a.inspect}" } }> " +
            "#{ @children.inject('') { |memo,c| memo + c.inspect } } " +
            "</#{@name}>"
        end
    end

    ##
    # Keeps text data.
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
    # Keeps a single Attribute of a Node.
    #
    class Attribute
        attr_reader :name, :value

        def initialize
            @name, @value = '', ''
        end

        def inspect
            "#{@name}=#{@value.inspect}"
        end
    end

    ##
    # Parses a string into a Document of Nodes and Attributes
    #
    class Parser

        ##
        # Parses the passed +string+ into a Document.
        #
        def parse string
            str = string.dup
            doc = Document.new

            #TODO remove doctype
            while str.length > 0
                node, str = NodeParser.new.parse str
                doc.roots << node
            end

            doc
        end

    end

    ##
    # Parses a single node.
    # Ignores whitespace.
    #
    class NodeParser
        def parse string
            str = string.dup
            node = Node.new

            pos = :before_start
            trunc = true

            # parse start tag
            while str.length > 0
                char = str[0..0]

                case pos
                when :before_start
                    pos = :tag_name if char == '<'
                when :tag_name
                    case char
                    when '>' then break
                    when /\s/ then pos = :attributes
                    else node.name << char
                    end
                when :attributes
                    break if char == '>'

                    unless char =~ /\s/
                        attr, str = AttrParser.new.parse str
                        node.attributes << attr
                        trunc = false # otherwise it would erase the closing '>'
                    end
                end

                str = str[1..-1] if trunc
                trunc = true
            end

            # remove trailing '>'
            str = str[1..-1]

            # parse data or nodes
            node.children, str = ChildrenParser.new.parse str

            # remove end tag
            end_tag = "</#{node.name}>"
            str = str[end_tag.length..-1] if str.start_with? "</#{node.name}>"

            [node, str]
        end
    end

    class AttrParser
        def parse string
            str = string.dup

            attr = Attribute.new
            pos = :name
            escaped = false

            while str.length > 0
                char = str[0..0]

                case pos
                when :name
                    case char
                    when '=' then pos = :before_value
                    else attr.name << char
                    end
                when :before_value
                    case char
                    when '"'
                        pos = :in_quote
                    else
                        pos = :in_value
                        attr.value << char
                    end
                when :in_quote
                    case char
                    when '\\'
                        if escaped
                            attr.value << '\\'
                            escaped = false
                        else
                            escaped = true
                        end
                    when '"'
                        if escaped
                            attr.value << char
                            escaped = false
                        else
                            str = str[1..-1]
                            break
                        end
                    else
                        attr.value << '\\' if escaped
                        attr.value << char
                        escaped = false
                    end
                when :in_value
                    if char =~ /\s|>/ then break
                    else attr.value << char
                    end
                end

                str = str[1..-1]
            end

            [attr, str]
        end
    end

    class ChildrenParser
        def parse string
            str = string.dup

            nodes = []

            while str.length > 0
                char = str[0..0]

                case char
                when '<'
                    # stop if this is an end tag
                    break if '/' == str[1..1]
                    # else start node parsing
                    node, str = NodeParser.new.parse str
                    nodes << node
                else
                    data, str = DataParser.new.parse str
                    nodes << data
                end
            end

            [nodes, str]
        end
    end

    class DataParser
        def parse string
            str = string.dup

            data = Data.new

            while str.length > 0
                char = str[0..0]

                case char
                when '<' then break # stop on tag
                else data.data << char # else add char
                end
                
                str = str[1..-1]
            end

            [data, str]
        end
    end

    ##
    # Shortcut for +Dome::Parser.new.parse string+.
    #
    def self.parse string
        Parser.new.parse string
    end

end

