# coding: utf-8
# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/ulid'

Benchmark.ips do |x|
  x.report('ULID#to_s / After #7') { ULID.generate.to_s }

  x.compare!
end
