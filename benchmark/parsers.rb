# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require_relative('../lib/ulid')

fixed_integer = SecureRandom.random_number(ULID::MAX_INTEGER)
sample = ULID.sample.freeze
encoded = sample.to_s

Benchmark.ips do |x|
  x.report('ULID.parse') { ULID.parse(encoded) }
  x.report('ULID.from_integer') { ULID.from_integer(fixed_integer) }
  x.compare!
end
