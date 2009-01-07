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
# This file contains the XPath related classes and functions.
# It also extends the Document class to provide XPath functionality.
#

module Dome

    ##
    # Enhances the Document class with Hpricot-like functionality for using XPath.
    #
    class Document
        def / path
            XPath.new(path).all self
        end

        def % path
            XPath.new(path).first self
        end

        def each path
            XPath.new(path).each(self) { |e| yield e }
        end
    end

    ##
    # Stores an XPath over a Document.
    # Can be used to iterate over all the Nodes identified by the XPath
    # and to extract all of them or only the first one.
    #
    class XPath
        ##
        # Shortcut for +XPath#each+.
        #
        def self.each doc, path
            XPath.new(path).each(doc) { |e| yield(e) }
        end

        ##
        # Shortcut for +XPath#first+.
        #
        def self.first doc, path
            XPath.new(path).first doc
        end

        ##
        # Shortcut for +XPath#match+.
        #
        def self.match doc, path
            XPath.new(path).all doc
        end

        ##
        # Shortcut for +XPath#all+.
        #
        def self.all doc, path
            XPath.new(path).all doc
        end

        ##
        # Creates a new XPath from the String +path+.
        #
        def initialize path
            @path = []
            self.parse path
        end

        ##
        # Iterates over all elements matched by the given XPath and yields the
        # given +block+ for each of them.
        #
        def each doc
            self.all(doc).each { |n| yield(n) }
        end

        ##
        # Returns the first element matching the given XPath.
        #
        def first doc
            self.first_node doc.root, @path
        end

        ##
        # Returns an Array of all elements matching the given XPath.
        #
        def all doc
            self.all_nodes(doc.root, @path)
        end

        ##
        # Alias for +XPath#all+.
        #
        def match doc
            self.all doc
        end

        def inspect
            @path.inject('') { |memo,parser| memo + parser.inspect }
        end

        protected

        ##
        # Parses the +string+ into an Array of +XPath::Parsers+.
        #
        def parse string
            str = string.dup
            str = '/' + str unless str[0..0] == '/'

            while str.length > 0
                nodep = NodeParser.new
                str = nodep.parse str
                @path << nodep
            end
        end

        ##
        # Does the actual work for +XPath#all+.
        #
        # Retrieves the next element under the current +node+ matching the first
        # parser in the +path+ and calls +all_nodes+ recursively for it with the
        # first parser removed from the +path+.
        # If the +path+ is empty, the +node+ has been found and +[node]+ will be
        # returned.
        #
        # The outermost function call will return an Array containing all the nodes
        # matching the given path.
        #
        def all_nodes node, path
            if not node
                []
            elsif path.empty?
                [node]
            else
                path[0].all(node, path).collect { |sub|
                    self.all_nodes sub, (path[1..-1] || [])
                }.flatten
            end
        end

        ##
        # Does the actual work for +XPath#first+.
        #
        # Retrieves the first element under the current +node+ matching the first
        # parser in the +path+ and calls +first_node+ recursively for the result.
        # If the path is empty or no valid node was found in the last iteration,
        # the +node+ or +nil+ is returned.
        #
        ##TODO: .. parser needs to go up! save that inside the parent parser, which
        # must keep the thing and do the .. himself. else there would only be a throw
        #
        def first_node node, path
            ret = if path.empty? or not node then node
            else first_node path[0].first(node, path), path[1..-1]
            end
            ret
        end

        class XPathParserError < RuntimeError
        end

        class NodeParser
            def initialize
                @tag, @attr_parsers = '', []
            end

            def parse string
                str = string.dup[1..-1] # dup and remove leading '/'

                pos = :undefined
                trunc = true

                while str.length > 0
                    char = str[0..0]

                    case pos
                    when :undefined
                        case char
                        when '/'
                            @tag = :somewhere
                            break
                        when '*'
                            @tag = :star
                            pos = :star
                        when '['
                            # maybe that is possible after all?
                            raise XPathParserError.new "Unexpected '[' before tag descriptor, expected one of '*', '/' or literal"
                        else
                            @tag << char
                            pos = :tag
                        end
                    when :tag
                        case char
                        when '[' then pos = :attributes
                        when '*' then raise XPathParserError.new "Unexpected '*' after tag start, expected one of '/', '[' or literal"
                        when '/' then break
                        else @tag << char
                        end
                    when :star
                        case char
                        when '/' then break
                        when '[' then pos = :attributes
                        else raise XPathParserError.new "Unexpected '#{char}' after '*', expected one of '[' or '/'"
                        end
                    when :attributes ##TODO: multiple attributes?
                        case char
                        when ']'
                            pos = :attrend
                        when '/'
                            raise XPathParserError.new "Unexpected '/' in attribute descriptor"
                        else
                            attrp = AttrParser.new
                            str = attrp.parse str
                            @attr_parsers << attrp
                            # don't delete the next token, since we don't know what it'll be
                            trunc = false
                        end
                    when :attrend
                        case char
                        when '/' then break
                        else raise XPathParserError.new "Unexpected '#{char}' after attribute descriptor, expected '/'"
                        end
                    end

                    str = str[1..-1] if trunc
                    trunc = true
                end

                str
            end

            ##
            # Returns an Array of all Nodes under +node+ matching this NodeParser.
            ##TODO: Root node is not root node, but rather an imaginary empty node?
            #
            def all node, path, first = true
                case @tag
                when :somewhere
                    # try applying the next parser to the children and then
                    # to the grand children etc.
                    ##TODO: '//' at the end of the xpath?
                    idx = 0
                    idx_r = -1 * node.children.length - 1

                    ret =
                        node.children.find_all { |child|
                            idx += 1
                            idx_r += 1
                            path[1].matches? child, idx, idx_r
                        } +
                        node.children.collect { |child|
                            self.all child, path, false
                        }.flatten

                    path.delete_if { true } if first
                    ret
                else
                    idx = 0
                    idx_r = -1 * node.children.length - 1
                    node.children.find_all { |child|
                        idx += 1
                        idx_r += 1
                        self.matches? child, idx, idx_r
                    }
                end
            end

            ##
            # Returns the first child of node matching this NodeParser or nil,
            # if no match is found.
            #
            def first node, path
                case @tag
                when :somewhere
                    path = path[1..-1]
                    path.empty? ? nil : path[0].somewhere_first(node)
                else
                    idx = 0
                    idx_r = -1 * node.children.length - 1
                    node.children.detect { |child|
                        idx += 1
                        idx_r += 1
                        self.matches? child, idx, idx_r
                    }
                end
            end

            ##
            # Returns true if the +node+ with the index +idx+ and the reverse index +idx_r+
            # matches this NodeParser. Otherwise returns false.
            #
            def matches? node, idx, idx_r
                node.is_a? Node and
                ( @tag == :star or node.name == @tag ) and
                @attr_parsers.all? { |a| a.matches? node, idx, idx_r }
            end

            ##
            # Implements the '//' operator for a call to +#first+.
            # Returns a single Node or +nil+.
            #
            def somewhere_first node
                idx = 0
                idx_r = -1 * node.children.length - 1

                node.children.each { |child|
                    idx += 1
                    idx_r += 1
                    return child if self.matches? child, idx, idx_r
                    grandchild = child.children.detect { |gc| somewhere_first gc }
                    return grandchild if grandchild
                }
                nil
            end

            def inspect
                ret = 
                    case @tag
                    when :star then "/*"
                    when :somewhere then "/"
                    else "/#{@tag}"
                    end

                ret += '[' + @attr_parsers.inject(nil) { |memo,parser|
                    memo.nil? ? parser.inspect : memo + ',' + parser.inspect
                } + ']' unless @attr_parsers.empty?
                ret
            end
        end

        class AttrParser
            def initialize
                @name, @value, @count = '', '', nil
            end

            def parse string
                str = string.dup

                pos = :start
                escaped = false
                trunc = true

                while str.length > 0
                    char = str[0..0]

                    case pos
                    when :start
                        case char
                        when '@'
                            pos = :attribute
                        else
                            pos = :count
                            trunc = false
                        end
                    when :count
                        num = /^[0-9]+/
                        last = /^last\(\)(-([0-9]+))?/

                        if (m = num.match str)
                            @count = m[0].to_i
                            str = str[(m[0].length)..-1]
                        elsif (m = last.match str)
                            @count = -1 - m[2].to_i
                            str = str[(m[0].length)..-1]
                        else
                            raise XPathParserError.new "Illegal attribute descriptor with neither numeric nor attribute argument found"
                        end

                        break
                    when :attribute
                        case char
                        when '@'
                            raise XPathParserError.new "Unexpected second '@' in attribute descriptor"
                        when '='
                            if @name.length == 0 then raise XPathParserError.new "Zero-length attribute given"
                            else pos = :quote_start
                            end
                        else @name << char
                        end
                    when :quote_start ##TODO: single and double quotes here and in html parser attributes
                        case char
                        when "'" then pos = :value
                        ##TODO: allow special values here?
                        else raise XPathParserError.new "Unquoted value in attribute descriptor, expecting ' (single quote)"
                        end
                    when :value
                        case char
                        when '\\'
                            if escaped
                                @value << char
                                escaped = false
                            else
                                escaped = true
                            end
                        when "'"
                            if escaped
                                @value << char
                                escaped = false
                            else
                                str = str[1..-1] # remove trailing "'"
                                break
                            end
                        else
                            @value << char
                        end
                    end

                    str = str[1..-1] if trunc
                    trunc = true
                end

                str
            end

            ##
            # Returns true if the AttrParser matches with the given
            # +node+'s attributes, its index +idx+ and its reverse index +idx_r+.
            #
            def matches? node, idx, idx_r
                node.attributes.any? { |attr|
                    (attr.name == @name and attr.value == @value) or
                    @count == idx or @count == idx_r
                }
            end

            def inspect
                "#{@name}='#{@value}'"
            end
        end

    end

end

