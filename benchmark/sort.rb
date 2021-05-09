# coding: utf-8
# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/ulid'

frozen_ulid_objects = ULID.sample(10000).map(&:freeze)
ulid_strings = frozen_ulid_objects.map(&:to_s)
non_cached_ulid_objects = ulid_strings.map { |s| ULID.parse(s) }

Benchmark.ips do |x|
  x.report('Sort ULID instance / After second sorting, cache will be work. So this benchmark is not accurate.') do
    non_cached_ulid_objects.shuffle.sort
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
