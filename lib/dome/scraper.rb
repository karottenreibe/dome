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
# This file contains the CSS Scraper related classes and functions.
#

require 'dome/helpers/css'

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
            ex = Extractor.new self
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
        # Keeps a Scraper Result.
        # The data in the Result can be accessed either via the Hash-like method
        # +#[]+ or directly via the associated +attr_accessor+.
        #
        class Result

            ##
            # Stores +data+ in the Result under +sym+.
            #
            def []= sym, data
                define sym
                sym = "#{sym}=".to_sym
                self.send sym, data
            end

            ##
            # Retrieves the data associated with +sym+.
            #
            def [] sym
                self.send sym
            end

            ##
            # Adds an +attr_accessor+ for +sym+.
            #
            def define sym
                eval "def self.#{sym}; @#{sym}; end"
                eval "def self.#{sym}= x; @#{sym} = x; end"
            end

        end

        ##
        # The result the extraction produced
        #
        attr_reader :result

        ##
        # +tree+ must be the Tree on which the Extractor should operate.
        #
        def initialize tree
            @tree = tree
            @result = Result.new
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
        # - +"@attribute"+ to select an attribute value
        # - +"$index"+ or +"$range"+ to select the Data descendant(s) with the given +index+
        #   or within the given +range+. Both are zero-based.
        # - +:inner_text+ to select the +inner_text+ of the Element
        # - +:inner_html+ to select the +inner_html+ of the Element
        # - +:outer_html+ to select the +outer_html+ of the Element
        # and +storage+ being a symbol which signifies the attribute to store the
        # extracted data in.
        #
        def scrape hash
            raise "nothing selected so far" unless @selected

            @selected.each do |elem|
                hash.each do |k,v|
                    @result[v] =
                        case key
                        when :inner_text, :inner_html, :outer_html then elem.send k
                        when /^@./ then elem[k[1..-1]]
                        when /^\$[0-9]+(\.\.\.?[0-9]+)?$/ then scrape_data eval(k[1..-1])
                        else raise "invalid selector #{k.inspect} given to Extractor#store"
                        end
                end
            end
        end

        protected

        ##
        # Scrapes the +idx+'th Data Node under the given +element+.
        # Returns either the Data Node or an Integer signifying how many
        # Data Nodes still need to be searched.
        #
        def scrape_data element, range
            idx = 0
            ret = []
            @children.each { |child|
                if child.is_a? Data
                    ret << child if range.include? idx
                    idx += 1
                end
            }
            ret
        end

    end

end

