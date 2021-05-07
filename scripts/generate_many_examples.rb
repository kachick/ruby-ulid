# coding: us-ascii
# frozen_string_literal: true

require 'bundler/setup'
require_relative '../lib/ulid'
require_relative '../lib/ulid/uuid'
require_relative '../test/many_data/fixtures/example'

min = Time.at(0).utc
max = Time.at(56294995342131/200r).utc #=> 10889-08-02 05:31:50.655 UTC

example_count = 10000
ulids = []
examples = example_count.times.map do
  # https://stackoverflow.com/a/2683929/1212807
  time = Time.at(((max.to_r - min.to_r) * SecureRandom.rand) + min.to_r).utc
  ulid = ULID.generate(moment: time)
  ulids << ulid
  Example.new(
    time: time,
    to_time: ulid.to_time,
    string: ulid.to_s,
    integer: ulid.to_i,
    timestamp: ulid.timestamp,
    randomness: ulid.randomness,
    inspect: ulid.inspect,
    uuidv4: ulid.to_uuidv4
  )
end

raise 'Very rare case happened or bug exists' unless ulids.uniq.size == example_count

Marshal.dump(examples, STDOUT)
