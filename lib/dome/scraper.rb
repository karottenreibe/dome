#
# This file contains the CSS Scraper related classes and functions.
#

require 'rubygems'
require 'ohash'
require 'dome/css'

module Dome

    ##
    # Enhances the Tree class with Scraper functionality.
    #
    class Tree

        ##
        # Scrapes data from the Tree by evaluating the given +block+ on an
        # Scraper object.
        #
        def scrape( &block )
            raise "Tree#extract expects a block" unless block_given?
            ex = Scraper.new(self)
            ex.instance_exec(ex, &block)
            ex.result
        end
    end

    ##
    # Used to scrape information from a Tree.
    # Best used with the +Tree#scrape+ method.
    #
    class Scraper

        ##
        # The result the extraction produced
        #
        attr_reader :result

        ##
        # +tree+ must be the Tree on which the Scraper should operate.
        #
        def initialize( tree )
            @tree   = tree
            @result = OpenHash.new
        end

        ##
        # Selects all Elements matching the given path.
        #
        # The given hash must either be of form selector => storage, with selector
        # being any of:
        #
        # - :element               to select the whole element
        # - "@attribute"           to select an attribute value
        # - "$index" or "$range"   to select the Data descendant(s) with the
        #                          given index or within the given range. Both
        #                          are 1-based.
        # - :inner_text            to select the Element#inner_text()
        # - :inner_html            to select the Element#inner_html()
        # - :outer_html            to select the Element#outer_html()
        #
        # or can just be a symbol. In that case, :element => :symbol is assumed.
        #
        # Storage has to be a symbol, which signifies where the extracted data is stored
        # in the result hash.
        #
        # All the storage places are guaranteed to be initialized with an Array, even if no
        # element was selected.
        #
        def all( path, hash )
            scrape(path, hash, :/) do |storage, selector, elements|
                @result[storage] ||= Array.new
                elements.each { |element| @result[storage] << select(element, selector) }
            end
        end

        ##
        # Same as #all(), except that all the storage places will directly contain
        # the scraped data instead of an array.
        #
        def first( path, hash )
            scrape(path, hash, :%) do |storage, selector, element|
                @result[storage] = select(element, selector)
            end
        end

        private

        ##
        # Helper method for #all() and #first(). Does the element selection and
        # yields the results thereof in combination with each storage place and
        # the according selector.
        #
        def scrape( path, hash, operator )
            hash = { :element => hash } unless hash.is_a?(Hash)
            selected = @tree.send(operator, path)
            hash.each do |selector,storage|
                yield(storage, selector, selected)
            end
        end

        ##
        # Transforms the given selector into data from the given elem.
        #
        def select(elem, selector)
            case selector
            when :element                              then elem
            when :inner_text, :inner_html, :outer_html then elem.send(selector)
            when /^@./                                 then elem[selector[1..-1]]
            when /^\$[0-9]+$/
                i = selector[1..-1].to_i
                scrape_data(elem, i..i)
            when /^\$[0-9]+(\.\.\.?[0-9]+)?$/
                m = /\.\.\.?/.match(selector)
                first, last = m.pre_match[1..-1].to_i, m.post_match.to_i
                last -= 1 if m[0] == "..."
                scrape_data(elem, first..last)
            else raise "invalid selector #{selector.inspect} given"
            end
        end

        ##
        # Scrapes the +idx+'th Data Node under the given +element+.
        # Returns the found Data Nodes' values joined together into a single String.
        #
        def scrape_data( element, range )
            idx = 1
            ret = []
            element.children.each { |child|
                if child.is_a?(Data)
                    ret << child.value if range.include?(idx)
                    idx += 1
                end
            }
            ret.join
        end

    end

end

