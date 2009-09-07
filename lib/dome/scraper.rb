#
# This file contains the CSS Scraper related classes and functions.
#

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
        def scrape &block
            raise "Tree#extract expects a block" unless block_given?
            ex = Scraper.new self
            ex.instance_exec ex, &block
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
        def initialize tree
            @tree = tree
            @result = Hash.new
        end

        ##
        # Selects all Elements matching +path+.
        # Alias: +all+
        #
        def / path
            @selected = @tree/path
        end

        ##
        # Selects the first Element matching +path+.
        # Alias: +first+
        #
        def % path
            @selected = @tree%path
        end

        alias_method :all, :/
        alias_method :first, :%

        ##
        # Extracts data from the last selected Elements and stores them in the
        # result attribute.
        # The given +hash+ must be of form +selector=>storage+, with +selector+
        # being any of:
        # - +:element+ to select the whole element
        # - +"@attribute"+ to select an attribute value
        # - +"$index"+ or +"$range"+ to select the Data descendant(s) with the given +index+
        #   or within the given +range+. Both are 1-based.
        # - +:inner_text+ to select the +inner_text+ of the Element
        # - +:inner_html+ to select the +inner_html+ of the Element
        # - +:outer_html+ to select the +outer_html+ of the Element
        # and +storage+ being a symbol which signifies where in the result hash to store the
        # extracted data in.
        # All the +storage+ places are guaranteed to be initialized with an Array, even if nothing
        # was selected.
        #
        # If an additional block is given, it is passed all results of the scraping operation and
        # expected to return a substitution for each result, i.e. it may apply additional transformation
        # in-place on the results.
        #
        def scrape hash
            raise "nothing selected so far" unless @selected

            hash.each do |selector,storage|
                @result[storage] ||= []

                @selected.each do |elem|
                    result =
                        case selector
                        when :element then elem
                        when :inner_text, :inner_html, :outer_html then elem.send selector
                        when /^@./ then elem[selector[1..-1]]
                        when /^\$[0-9]+$/
                            i = selector[1..-1].to_i
                            scrape_data elem, i..i
                        when /^\$[0-9]+(\.\.\.?[0-9]+)?$/
                            m = /\.\.\.?/.match selector
                            first,last = m.pre_match[1..-1].to_i, m.post_match.to_i
                            last -= 1 if m[0] == "..."
                            scrape_data elem, first..last
                        else raise "invalid selector #{selector.inspect} given to Scraper#scrape"
                        end
                    result = yield result if block_given?
                    @result[storage] << result
                end
            end
        end

        protected

        ##
        # Scrapes the +idx+'th Data Node under the given +element+.
        # Returns the found Data Nodes' values joined together into a single String.
        #
        def scrape_data element, range
            idx = 1
            ret = []
            element.children.each { |child|
                if child.is_a? Data
                    ret << child.value if range.include? idx
                    idx += 1
                end
            }
            ret.join
        end

    end

end

