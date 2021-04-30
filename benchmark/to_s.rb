require 'benchmark/ips'
require_relative '../lib/ulid'

ulid = ULID.generate
ulid.to_s # Cached the result

many_ulids = 1000000.times.map do
  ULID.generate
end

Benchmark.ips do |x|
  x.report('ULID#to_s first time, having some overhead from taking the object pool') do
    if non_cached_ulid = many_ulids.pop
      non_cached_ulid.to_s
    else
      raise 'shortage ulid pool'
    end
  end

  x.report('ULID#to_s multiple times makes faster') { ulid.to_s }

  x.compare!
end
