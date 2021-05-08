# coding: utf-8
# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/ulid'

monotonic_generator = ULID::MonotonicGenerator.new
fixed_integer = SecureRandom.random_number(ULID::MAX_INTEGER)
sample = ULID.sample.freeze
moment = sample.to_time
period = moment..(moment + 10000000)
encoded = sample.to_s

Benchmark.ips do |x|
  x.report('ULID.generate') { ULID.generate }
  x.report('ULID::MonotonicGenerator#generate') { monotonic_generator.generate }
  x.report('ULID.parse') { ULID.parse(encoded) }
  x.report('ULID.from_integer') { ULID.from_integer(fixed_integer) }
  x.report('ULID.min with no arguments is optimized') { ULID.min }
  x.report('ULID.min with moment(Time)') { ULID.min(moment: moment) }
  x.report('ULID.max with no arguments is optimized') { ULID.max }
  x.report('ULID.max with moment(Time)') { ULID.max(moment: moment) }
  x.report('ULID.sample with no arguments') { ULID.sample }
  x.report('ULID.sample with period') { ULID.sample(period: period) }
  x.report('ULID.at') { ULID.at(Time.now) }
  x.compare!
end
