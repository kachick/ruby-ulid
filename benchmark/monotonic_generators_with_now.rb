# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require_relative('../lib/ulid')

monotonic_generator1 = ULID::MonotonicGenerator.new
monotonic_generator2 = ULID::MonotonicGenerator.new

Benchmark.ips do |x|
  x.report('ULID.encode') { ULID.encode } # # To compare with no Monotonicity
  x.report('ULID::MonotonicGenerator#encode') { monotonic_generator1.encode }
  x.report('ULID::MonotonicGenerator#generate.to_s') { monotonic_generator2.generate.to_s }
  x.compare!
end
