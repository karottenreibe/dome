#!/usr/bin/env ruby
require 'test/unit'
require 'lib/dome/parser'
require 'lib/dome/xpath'

module Dome
    class XPath
        attr_reader :path

        class NodeParser
            attr_reader :tag, :attr_parsers
        end

        class AttrParser
            attr_reader :attr, :value
        end
    end
end

class XPathTests < Test::Unit::TestCase
    include Dome

	def self.val
		@@val
	end

	def self.val= v
		@@val = v
	end
end

