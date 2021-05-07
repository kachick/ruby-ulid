# coding: utf-8
# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/ulid'

monotonic_generator = ULID::MonotonicGenerator.new
fixed_integer = SecureRandom.random_number(ULID::MAX_INTEGER)

Benchmark.ips do |x|
  x.report('ULID.generate') { ULID.generate }
  x.report('ULID::MonotonicGenerator#generate') { monotonic_generator.generate }
  x.report('ULID.from_integer with random value') { ULID.from_integer(SecureRandom.random_number(ULID::MAX_INTEGER)) }
  x.report("ULID.from_integer with fixed integer `#{fixed_integer}` (To compare randomizing overhead)") { ULID.from_integer(fixed_integer) }
  x.report('ULID.min with no arguments is optimized') { ULID.min }
  x.report('ULID.max with no arguments is optimized') { ULID.max }
  x.report('ULID.sample') { ULID.sample }
  x.report('ULID.at') { ULID.at(Time.now) }
  x.compare!
end
