# coding: us-ascii
# frozen_string_literal: true

require('bundler/setup')
require_relative('../lib/ulid')

require('time') # To use `Time.parse` for readability, Do not depend on tests

require('perfect_toml')

# Needless to rollback. This is rough script.
ENV['TZ'] = 'UTC'

# 1999 is not ancient to me. But ancient in `Time` objects.
ancient = Time.at(0)..Time.parse('1999/12/31')

# Birthday of `Doraemon` is the near feature!
recently = Time.parse('2020/1/1')..Time.parse('2112/9/3')

# Quoted from https://en.wikipedia.org/wiki/Timeline_of_the_far_future
#
# Years from now - 2000
# To compensate, either leap seconds will have to be added at multiple times during the month or multiple leap seconds will have to be added at the end of some or all months.
distant_future = Time.parse("#{2021 + 2000}/1/1")...Time.parse("#{2021 + 4000}/12/31")

# When we want to use this timestamp...? :)
# Omit because of years in TOML should be less than 10000: https://github.com/toml-lang/toml/blob/2431aa308a7bc97eeb50673748606e23a6e0f201/toml.abnf#L180
# limit_of_the_ulid = (ULID.max.to_time - 1000000)..ULID.max.to_time
limit_of_toml = Time.parse('9999/1/1')..Time.parse('9999/12/31')

examples = [ancient, recently, distant_future, limit_of_toml].each_with_object({}) do |period, acc|
  ulids = ULID.sample(1000, period:)
  if ulids.uniq!
    raise('Very rare case happened or bug exists')
  end

  ulids.sort.each do |ulid|
    unless period.cover?(ulid.to_time)
      raise(ULID::Error, 'Crucial bug exists!')
    end

    acc[ulid.to_s] = {
      to_time: ulid.to_time,
      integer: ulid.to_i,
      timestamp: ulid.timestamp,
      randomness: ulid.randomness,
      octets: ulid.octets,
      inspect: ulid.inspect,
      uuidish: ulid.to_uuidish,
      uuidv4: ulid.to_uuidv4(force: true)
    }
  end
end

unless examples.size == 4000
  raise(ScriptError, 'This script should have a bug! (or interpreter bug...?)')
end

puts('The generated samples are below')
p(examples.values.sample(20))

filename = "snapshots_#{Time.now.strftime('%Y-%m-%d_%H-%M')}.toml"
output_path = "#{File.expand_path('.')}/test/many_data/fixtures/#{filename}"

PerfectTOML.save_file(output_path, examples)

puts('-' * 72)

puts("Need to bump unmarshalling code in `test/many_data/test_snapshots.rb` with #{filename}")
