require 'benchmark/ips'
require_relative '../lib/ulid'

many_ulid_strings = 10000.times.map do
  ULID.from_integer(SecureRandom.random_number(ULID::MAX_INTEGER)).to_s
end

raise 'Setup error' unless many_ulid_strings.uniq.size == 10000

Benchmark.ips do |x|
  x.report('ULID.parse') do
    ULID.parse(many_ulid_strings.sample)
  end
end
