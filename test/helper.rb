# coding: us-ascii
# frozen_string_literal: true

require 'warning'
require 'test/unit'

if Warning.respond_to?(:[]=) # @TODO Removable this guard after dropped ruby 2.6
  Warning[:deprecated] = true
  Warning[:experimental] = true
end

Warning.process do |warning|
  :raise
end

require_relative '../lib/ulid'
