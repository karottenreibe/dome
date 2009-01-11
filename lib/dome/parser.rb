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

require 'spectre/spectre'
require 'spectre/std'
require 'dome/atoms'

module Dome

    include Spectre
    include Spectre::StringParsing

    ##
    # Parses a string into a Document of Nodes and Attributes.
    # Parsing is started by calling +parse+.
    # The same parser can be used to parse different documents.
    #
    class Parser

        ##
        # Creates the grammar.
        #
        def initialize
            root_a = lambda { |val,closure|
                doc.roots << closure[:sub]
            }
            element_a = lambda { |val,closure|
                closure.parent[:sub] << closure[:element]
            }
            attr_set_a = lambda { |val,closure|
            }
            tagname_a = lambda { |val,closure|
                closure[:element] = Node.new
                closure[:element].tag = val
            }
            attribute_a = lambda { |val,closure|
                attrib = Attribute.new
                attrib.name = closure[:name]
                attrib.value = closure[:value]
                closure.parent[:element].attributes << attrib
            }
            inside_a = lambda { |val,closure|
                closure.parent[:element].attributes << closure[:sub]
            }

            @parser = Grammar.new do |doc|
                var :document   => close( element[root_a] ).*
                    :element    =>
                        close(
                            (elem|empty_elem)[element_a]
                        )
                    :elem       => start_tag >> inside >> end_tag
                    :start_tag  => '<' >> tagname >> attribute.* >> '>'
                    :end_tag    => '</' >> closure(:tag) >> '>'
                    :empty_elem => '<' >> tagname >> attribute.* >> '/>'
                    :tagname    => name[tagname_a]
                    :attribute  => close( attr[attribute_a] )
                    :attr       =>
                        ' ' >> name[:name] >> '=' >>
                        close(
                            '"'[:quote] >>
                            ( ( ~ ).* )[:value] >>
                            closure(:quote)
                        )
                    :name       => alpha_char >> alnum_char.*
                    :inside     => ( data|element )[inside_a].*
                    :data       => ( ( ~char('<') ).+ )[:data]
                @parser = document
            end
        end

        ##
        # Parses the passed +string+ into a Document.
        #
        def parse string
        end

    end

    ##
    # Shortcut for +Dome::Parser.new.parse string+.
    #
    def self.parse string
        Parser.new.parse string
    end

end

