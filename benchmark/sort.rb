require 'benchmark/ips'
require_relative '../lib/ulid'

frozen_ulid_objects = 10000.times.map do
  ULID.generate.freeze
end
ulid_strings = frozen_ulid_objects.map(&:to_s)
non_cached_ulid_objects = frozen_ulid_objects.map(&:dup)

Benchmark.ips do |x|
  x.report('Sort ULID instance') do
    non_cached_ulid_objects.shuffle.sort # After second sorting, cache will be work. So this benchmark is not accurate.
  end

  x.report('Sort frozen ULID instance(some values cached)') do
    frozen_ulid_objects.shuffle.sort
  end

  x.report('Sort by String encoded ULIDs') do
    ulid_strings.shuffle.sort
  end

  x.compare!
end

# I'll check to be sure sorting result is correct.

unless ulid_strings == non_cached_ulid_objects.map(&:to_s)
  raise 'Crucial Bug exists!'
end

unless ulid_strings == frozen_ulid_objects.map(&:to_s)
  raise 'Crucial Bug exists!'
end
