#!/usr/bin/env ruby
require 'test/unit'
require 'lib/dome/document'
require 'lib/dome/xpath'

class XPathTests < Test::Unit::TestCase
    include Dome

	def self.val
		@@val
	end

	def self.val= v
		@@val = v
	end
end

