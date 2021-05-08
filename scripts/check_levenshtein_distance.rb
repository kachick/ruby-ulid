# coding: us-ascii
# frozen_string_literal: true

require 'bundler/setup'
require_relative '../lib/ulid'

raise "Should specify same length 2 strings: #{ARGV.inspect}" unless (ARGV.size == 2) && (ARGV[0].size == ARGV[1].size)
puts  DidYouMean::Levenshtein.distance(ARGV[0], ARGV[1])
