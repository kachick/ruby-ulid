# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require_relative('../lib/ulid')

monotonic_generator1 = ULID::MonotonicGenerator.new
monotonic_generator2 = ULID::MonotonicGenerator.new

msec = ULID.generate.milliseconds

Benchmark.ips do |x|
  x.report('ULID.encode with different time') { ULID.encode(moment: msec += 1) } # To compare with no Monotonicity
  x.report('ULID::MonotonicGenerator#encode with different time') { monotonic_generator1.encode(moment: msec += 1) }
  x.report('ULID::MonotonicGenerator#generate.to_s with different time') { monotonic_generator2.generate(moment: msec += 1).to_s }
  x.compare!
end
