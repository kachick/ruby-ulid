require 'benchmark/ips'
require_relative '../lib/ulid'

monotonic_generator = ULID::MonotonicGenerator.new

Benchmark.ips do |x|
  x.report('ULID.generate') { ULID.generate }
  x.report('Monotonic generating') { monotonic_generator.generate }
  x.compare!
end
