# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require('ulid')

raise("Bug to setup: #{ULID.methods(false)}") unless (ULID::VERSION == '1.0.0') && ULID::Identifier

products = []

Benchmark.ips do |x|
  x.report('ULID.generate') do
    products << ULID.generate
  end
end

# Below sections ensuring basic behaviors

# This Regexp taken from my code. But case sensitive
STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET = /\A(?<timestamp>[0-7][0123456789ABCDEFGHJKMNPQRSTVWXYZ]{9})(?<randomness>[0123456789ABCDEFGHJKMNPQRSTVWXYZ]{16})\z/.freeze

unless (products.size > 42) && (products.uniq === products) && products.all?(STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET) && products.all?(String)
  raise('Some bugs in the gem or this benchmark exists!')
end

p("`ulid-ruby gem - #{ULID::VERSION}` generated products: #{products.size} - sample: #{products.sample(5)}")
