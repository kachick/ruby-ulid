require 'benchmark/ips'
require_relative '../lib/ulid'

monotonic_generator = ULID::MonotonicGenerator.new

Benchmark.ips do |x|
  x.report('ULID.generate') { ULID.generate }
  x.report('Monotonic generating') { monotonic_generator.generate }
  x.report('ULID.min with no arguments is optimized') { ULID.min }
  x.report('ULID.max with no arguments is optimized') { ULID.max }
  x.compare!
end
