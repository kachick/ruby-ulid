# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require_relative('../lib/ulid')

Benchmark.ips do |x|
  x.report('ULID.encode') { ULID.encode }
  x.report('ULID.generate.to_s') { ULID.generate.to_s }
  x.report('ULID.generate') { ULID.generate }
  x.report('ULID.parse(ULID.encode)') { ULID.parse(ULID.encode) }
  x.compare!
end
