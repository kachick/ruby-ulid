# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

require('perfect_toml')

# https://github.com/kachick/ruby-ulid/issues/89
class TestSnapshots < Test::Unit::TestCase
  Example = Data.define(:integer, :timestamp, :randomness, :to_time, :inspect, :uuidish, :uuidv4, :octets)

  toml = PerfectTOML.load_file("#{__dir__}/fixtures/snapshots_2024-01-10_07-59.toml", symbolize_names: true)
  EXAMPLES = toml.to_h do |id, table|
    encoded = id.id2name
    [encoded, [encoded, Example.new(**table)]]
  end
  raise 'looks like misloading' unless EXAMPLES.size > 1000

  def assert_example(ulid, example)
    assert_equal(example.integer, ulid.to_i)
    assert_equal(example.inspect, ulid.inspect)
    assert_equal(example.timestamp, ulid.timestamp)
    assert_equal(example.randomness, ulid.randomness)
    assert_equal(example.uuidish, ulid.to_uuidish)
    assert_equal(example.uuidv4, ulid.to_uuidv4(force: true))
    assert_equal(example.to_time, ulid.to_time)
    assert_equal(example.octets, ulid.octets)
  end

  data(EXAMPLES)
  def test_decoders(ee)
    encoded, example = *ee
    ulid_parsed = ULID.parse(encoded)
    ulid_from_integer = ULID.from_integer(example.integer)
    ulid_from_uuidv4 = ULID.from_uuidish(ulid_parsed.to_uuidish)
    assert_equal(ulid_parsed, ulid_from_integer)
    assert_equal(ulid_parsed, ulid_from_uuidv4)

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
