require 'benchmark/ips'
require_relative '../lib/ulid'

Benchmark.ips do |x|
  x.report('ULID.generate') { ULID.generate }
  x.report('ULID.monotonic_generate') { ULID.monotonic_generate }
  x.report('ULID.generate.to_s') { ULID.generate.to_s }
end
