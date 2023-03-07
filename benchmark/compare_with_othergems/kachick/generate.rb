# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require('ulid')

raise("Bug to setup: #{ULID.methods(false)}") unless ULID.const_defined?(:MonotonicGenerator)

Benchmark.ips do |x|
  x.report('ULID.encode') do
    ULID.encode
  end
end
