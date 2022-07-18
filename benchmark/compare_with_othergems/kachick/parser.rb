# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require('ulid')

raise("Bug to setup: #{ULID.methods(false)}") unless ULID.const_defined?(:MonotonicGenerator)

example_encoded_string = '01F4A5Y1YAQCYAYCTC7GRMJ9AA'
products = []

Benchmark.ips do |x|
  x.report('ULID.decode_time') do
    products << ULID.decode_time(example_encoded_string)
  end
end

# Below sections ensuring basic behaviors

p("`ruby-ulid gem (this one) - #{ULID::VERSION}` generated products: #{products.size} - sample: #{products.sample(5)}")
