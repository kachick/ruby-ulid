# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

require('perfect_toml')

# https://github.com/kachick/ruby-ulid/issues/89
class TestSnapshots < Test::Unit::TestCase
  toml = PerfectTOML.load_file("#{__dir__}/fixtures/snapshots_2024-03-20_10-18.toml", symbolize_names: true)
  EXAMPLES = toml.to_h do |id, table|
    encoded = id.id2name
    [encoded, [encoded, table]]
  end
  raise 'looks like misloading' unless EXAMPLES.size > 100

  def assert_example(ulid, example)
    case example
    in { integer:, timestamp:, randomness:, to_time:, inspect:, uuidish:, uuidv4:, octets: }
      assert_equal(integer, ulid.to_i)
      assert_equal(inspect, ulid.inspect)
      assert_equal(timestamp, ulid.timestamp)
      assert_equal(randomness, ulid.randomness)
      assert_equal(uuidish, ulid.to_uuidish)
      assert_equal(uuidv4, ulid.to_uuid_v4(force: true))
      assert_equal(to_time, ulid.to_time)
      assert_equal(octets, ulid.octets)
    else
      raise(ArgumentError, 'given example is unknown format')
    end
  end

  data(EXAMPLES)
  def test_decoders(ee)
    encoded, example = *ee
    ulid_parsed = ULID.parse(encoded)

    case example
    in { integer:, uuidish: }
      ulid_from_integer = ULID.from_integer(integer)
      ulid_from_uuidish = ULID.from_uuidish(uuidish)
    else
      raise(ArgumentError, 'given example is unknown format')
    end

    assert_equal(ulid_parsed, ulid_from_integer)
    assert_equal(ulid_parsed, ulid_from_uuidish)

    assert_equal(encoded, ulid_parsed.to_s)
    assert do
      ULID.normalized?(encoded)
    end
    assert_example(ulid_parsed, example)
  end

  def test_sortable
    ulid_strings = []
    ulid_objects = []
    EXAMPLES.each_key do |encoded|
      ulid_strings << encoded
      ulid = ULID.parse(encoded)
      ulid_objects << ulid
    end

    assert_instance_of(ULID, ulid_objects.sample)
    assert_equal(ulid_strings.shuffle.sort, ulid_objects.shuffle.sort.map(&:to_s))
  end
end
