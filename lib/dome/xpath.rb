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
        # Alias for +XPath::all+.
        #
        def self.match doc, path
            XPath.all doc, path
        end

        ##
        # Shortcut for +XPath#all+.
        #
        def self.all doc, path
            XPath.new(path).match doc
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
        def each doc, &block
            self.each_node doc.root, @path, block
        end

        ##
        # Returns the first element matching the given XPath.
        #
        def first doc
            self.each_node doc.root, @path
        end

        ##
        # Returns an Array of all elements matching the given XPath.
        #
        def all doc
            ret = []
            self.each(doc) { |e| ret << e }
            ret
        end

        ##
        # Alias for +XPath#match+.
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
        # Does the actual work for +XPath#each+.
        #
        # Retrieves the next element under the current +node+ matching the first
        # parser in the +path+ and calls +each_node+ recursively for it with the
        # first parser removed from the +path+.
        # If the +path+ is empty, the +node+ has been found and the given +block+
        # is called for it.
        #
        def each_node node, path, block
            return nil unless node

            if path.empty?
                block.call node
            else
                path[0].each(node, path) { |sub|
                    each_node(sub, path[1..-1])
                }
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
            if path.empty? or not node then node
            else first_node path[0].first(node, path), path[1..-1]
            end
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

            def each node, path, &block
            end

            def first node, path
                case @tag
                case :somewhere
                    path = path[1..-1]
                    return path[0].somewhere_first node, path unless path.empty?
                    return nil
                when :star
                    idx = 0
                    node.children.detect { |child|
                        idx += 1
                        self.matches? node, idx
                    }
                else
                    node.children.detect { |child|
                        idx += 1
                        self.matches? node, idx
                    }
                end
            end

            def matches? node, idx
                child.is_a? Node and
                ( @tag == :star or node.tag == @tag ) and
                ( not @count or @count == idx ) and
                @attr_parsers.all? { |a| a.matches? child }
            end

            def somewhere_each node, path, &block
                node.children.each { |child|
                    self.each child, path[1..-1], &block if self.matches? child
                }
                node.children.each { |child|
                    self.each child, path[1..-1], &block if self.somewhere_first child, path
                }
            end

            def somewhere_first node, path
                node.children.detect { |child| self.matches? child } or
                node.children.detect { |child| self.somewhere_first child, path }
            end

            def inspect
                ret = "/#{@tag}"
                ret += '[' + @attr_parsers.inject(nil) { |memo,parser|
                    memo.nil? ? parser.inspect : memo + ',' + parser.inspect
                } + ']' unless @attr_parsers.empty?
                ret
            end
        end

        class AttrParser
            def initialize
                @attr, @value, @count = '', '', nil
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
                            if @attr.length == 0 then raise XPathParserError.new "Zero-length attribute given"
                            else pos = :quote_start
                            end
                        else @attr << char
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

            def each node
            end

            def first node
            end

            def inspect
                "#{@attr}='#{@value}'"
            end
        end

    end

end

