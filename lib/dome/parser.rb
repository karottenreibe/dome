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
# Git repo::    http://rubyforge.org/scm/?group_id=7589
#
# Contains the Parser that can transform a String into a HTML Document.
#

module Dome

    ##
    # Keeps a single Document.
    # All the root Nodes are stored in the +roots+ Array.
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
    # Keeps a single Node of a Document with its +name+ (String), +attributes+ (Array),
    # +children+ (Array) and +empty+ flag.
    #
    class Node
        attr_accessor :name, :attributes, :children, :empty
        
        def initialize
            @name, @attributes, @children, @empty = '', [], [], false
        end

        def empty?
            @empty
        end

        def inspect
            ret = "<#{@name}"
            ret += @attributes.inject(' ') { |memo,a| "#{memo} #{a.inspect}" } unless @attributes.empty?

            if @empty
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
        attr_reader :name, :value

        def initialize
            @name, @value = '', ''
        end

        def inspect
            "#{@name}=#{@value.inspect}"
        end
    end

    ##
    # Parses a string into a Document of Nodes and Attributes.
    # Parsing is started by calling +parse+.
    # The same parser can be used to parse different documents.
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
                ##TODO: user ChildrenParser here? so text will be processed as well
                ##TODO: Doctype working?
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
            ##TODO: if it's an end tag: consume it and return the modified string
            while str.length > 0
                char = str[0..0]

                case pos
                when :before_start
                    pos = :tag_name if char == '<'
                when :tag_name
                    case char
                    when '>'
                        break
                    when '/'
                        if str[1..1] == '>'
                            str = str[1..-1]
                            node.empty = true
                            break
                        else
                            node.name << char
                        end
                    when /\s/
                        pos = :attributes
                    else
                        node.name << char
                    end
                when :attributes
                    if char == '/' and str[1..1] == '>'
                        node.empty = true
                        str = str[1..-1]
                        break
                    end

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
            node.children, str = ChildrenParser.new.parse str unless node.empty?

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

