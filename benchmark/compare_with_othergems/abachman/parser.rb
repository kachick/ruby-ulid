# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require('ulid')

raise("Bug to setup: #{ULID.methods(false)}") unless ULID.const_defined?(:Identifier)

example_encoded_string = '01F4A5Y1YAQCYAYCTC7GRMJ9AA'

Benchmark.ips do |x|
  x.report('ULID.time') do
    ULID.time(example_encoded_string)
  end
end
