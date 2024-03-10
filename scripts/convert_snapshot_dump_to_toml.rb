# coding: us-ascii
# frozen_string_literal: true

require('bundler/setup')
require_relative('../lib/ulid')
require_relative('../test/many_data/fixtures/example')

require('perfect_toml')

path_prefix = "#{__dir__}/../test/many_data/fixtures/dumped_fixed_examples_"
timestamp = '2024-01-10_07-59'
without_ext = "#{path_prefix}#{timestamp}"
dump_data = File.binread("#{without_ext}.bin")
examples = Marshal.load(dump_data)
toml_prepared = examples.sort_by(&:integer).to_h { |example| [example.string, example.to_h.except(:string, :period)] }
PerfectTOML.save_file("#{without_ext}.toml", toml_prepared)

if toml_prepared == PerfectTOML.load_file("#{without_ext}.toml")
  raise 'there is a problem for serialization or deserialization in snapshots. Guessing Bug or https://github.com/toml-lang/toml/issues/538#issuecomment-1266209110'
end
