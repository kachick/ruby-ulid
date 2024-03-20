# coding: us-ascii
# frozen_string_literal: true

require('bundler/setup')
require_relative('../lib/ulid')
require_relative('../test/many_data/fixtures/example')
require('perfect_toml')

# Needless to rollback. This is rough script.
ENV['TZ'] = 'UTC'

path = ARGV.first
parsed_hash = PerfectTOML.load_file(path, symbolize_names: true)
updated_hash = parsed_hash.transform_values { |table|
  ulid = ULID.from_integer(table.fetch(:integer))
  # Specifying some redundant attributes to adjust the key order
  table.delete(:uuidv4)
  table.delete(:octets)
  table.merge(uuidish: ulid.to_uuidish, uuidv4: ulid.to_uuidv4(force: true), octets: ulid.octets)
}
PerfectTOML.save_file(path, updated_hash)
