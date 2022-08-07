# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require_relative('../lib/ulid')

sample = ULID.sample
moment = sample.to_time
period = moment..(moment + 10000000)

Benchmark.ips do |x|
  x.report('ULID.min with no arguments is optimized') { ULID.min }
  x.report('ULID.min with moment(Time)') { ULID.min(moment) }
  x.report('ULID.max with no arguments is optimized') { ULID.max }
  x.report('ULID.max with moment(Time)') { ULID.max(moment) }
  x.report('ULID.sample with no arguments') { ULID.sample }
  x.report('ULID.sample with period') { ULID.sample(period: period) }
  x.compare!
end
