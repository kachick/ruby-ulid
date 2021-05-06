# coding: utf-8
# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/ulid'

many_ulid_strings = ULID.sample(10000).map(&:to_s)

raise 'Setup error' unless many_ulid_strings.uniq.size == 10000

Benchmark.ips do |x|
  x.report('ULID.parse / After #7') do
    ULID.parse(many_ulid_strings.sample)
  end

  x.compare!
end
