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
#               or read the file LICENSE distributed with this software.
# Homepage::    http://dome.rubyforge.org/
# Git repo::    http://rubyforge.org/scm/?group_id=7589
#
# Contains the Parser that can transform a String into a HTML Document.
#

require 'rubygems'
require 'spectre/spectre'
require 'spectre/std'
require 'dome/atoms'
require 'pp'

module Dome

    include Spectre
    include Spectre::StringParsing

    ##
    # Parses a string into a Document of Elements and Attributes.
    # Parsing is started by calling +parse+.
    # The same parser can be used to parse different documents.
    #
    class Parser

        ##
        # Creates the grammar.
        #
        def initialize
            element_a = lambda { |match,closure|
                closure.parent[:sub] = closure[:element]
            }
            tagname_a = lambda { |match,closure|
                closure[:element] = Element.new
                closure[:element].name = match.value
            }
            attribute_a = lambda { |match,closure|
                attrib = Attribute.new
                attrib.name = closure[:name]
                attrib.value = closure[:value]
                closure.parent[:element].attributes << attrib
            }
            inside_a = lambda { |match,closure|
                closure.parent[:element].children << closure[:sub]
            }

            @grammar = Spectre::Grammar.new do |doc|
                var :document   => close( :element.to_n[lambda{ |match,closure| doc.roots << closure[:sub] }] ).*
                var :element    =>
                        close(
                            (:elem.to_n|:empty_elem)[element_a]
                        )
                var :elem       => :start_tag.to_n >> :inside >> :end_tag
                var :start_tag  => char('<') >> :tagname >> :attribute.to_n.* >> '>'
                var :end_tag    => '</' >> closed(:tag) >> '>'
                var :empty_elem => char('<') >> :tagname >> :attribute.to_n.* >> '/>'
                var :tagname    => :name.to_n[:tag][tagname_a]
                var :attribute  => close( :attr.to_n[attribute_a] )
                var :attr       =>
                        ' ' >> :name.to_n[:name] >> '=' >>
                        close(
                            '"'.to_n[:quote] >>
                            ( ( ~closed(:quote) ).* )[:value] >>
                            closed(:quote)
                        )
                var :name       => alpha_char >> alnum_char.*
                var :inside     => ( :data.to_n|:element )[inside_a].*
                var :data       => ( ( ~char('<') ).+ )[:data]

                var :parser     => :document
            end
        end

        ##
        # Parses the passed +string+ into a Document.
        #
        def parse string
            doc = Document.new
            @grammar.bind doc
            Spectre::StringParsing.parse string, @grammar
            doc
        end

    end

    ##
    # Shortcut for +Dome::Parser.new.parse string+.
    #
    def self.parse string
        Parser.new.parse string
    end

end

