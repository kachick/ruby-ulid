require 'benchmark/ips'
require_relative '../lib/ulid'

monotonic_generator = ULID::MonotonicGenerator.new
ulid_objects = 10000.times.map do
  monotonic_generator.generate
end
ulid_strings = ulid_objects.map(&:to_s)
unless ulid_objects == ulid_objects.sort
  raise 'Setup error'
end

unless ulid_strings == ulid_strings.sort
  raise 'Setup error'
end

unless ulid_strings.sort == ulid_objects.sort.map(&:to_s)
  raise 'Setup error'
end

Benchmark.ips do |x|
  x.report('Sort in ULID object') do
    ulid_objects.shuffle.sort
  end

  x.report('Sort in String') do
    ulid_strings.shuffle.sort
  end

  x.compare!
end
