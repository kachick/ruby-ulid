# coding: us-ascii
# frozen_string_literal: true

require('bundler/setup')
require_relative('../lib/ulid')
require_relative('../test/many_data/fixtures/example')

require('time')
require('json')

converter = Object.new

def converter.serialize_time(time)
  time.iso8601(3)
end

def converter.deserialize_time(serialized)
  Time.iso8601(serialized)
end

def converter.prepare(value)
  case value
  when Time
    value.iso8601(3)
  else
    value
  end
end

dump_data = File.binread("#{__dir__}/../test/many_data/fixtures/dumped_fixed_examples_2024-01-10_07-59.bin")
examples = Marshal.load(dump_data)
json_prepared = examples.map do |example|
  example.to_h.except(:period).transform_values { |v| converter.prepare(v) }
end.sort_by { |e| e.fetch(:integer)}

puts JSON.pretty_generate(json_prepared)

