# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require_relative('../lib/ulid')

sample = ULID.sample
moment = sample.to_time
period = moment..(moment + 10000000)

Benchmark.ips do |x|
  x.report('ULID.sample with big number') { ULID.sample(100000) }
  x.report('ULID.sample with big number and period(Range[Time])') { ULID.sample(100000, period:) }
  x.compare!
end
