# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require_relative('../lib/ulid')

Benchmark.ips do |x|
  x.report('ULID#bytes') { ULID.sample.bytes }
  x.report('ULID#timestamp_octets') { ULID.sample.timestamp_octets }
  x.report('ULID#randomness_octets') { ULID.sample.randomness_octets }

  x.compare!
end
