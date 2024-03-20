# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')
require_relative('fixtures/example')

require('perfect_toml')

# @TODO: Rewrite with data driven test, as for each ULID "test_ulid_271DRTPTX9Y1SHE8V0WAQ6XSK3"

# https://github.com/kachick/ruby-ulid/issues/89
class TestSnapshots < Test::Unit::TestCase
  toml = PerfectTOML.load_file("#{__dir__}/fixtures/snapshots_2024-01-10_07-59.toml")
  EXAMPLES = toml.each_pair.with_object([]) do |(encoded, table), list|
    list << Example.new(
      string: encoded,
      integer: table.fetch('integer'),
      timestamp: table.fetch('timestamp'),
      randomness: table.fetch('randomness'),
      to_time: table.fetch('to_time'),
      inspect: table.fetch('inspect'),
      uuidv4: table.fetch('uuidv4'),
      octets: table.fetch('octets'),
      period: nil
    )
  end

  def assert_example(ulid, example)
    assert_equal(example.string, ulid.to_s)
    assert_equal(example.integer, ulid.to_i)
    assert_equal(example.inspect, ulid.inspect)
    assert_equal(example.timestamp, ulid.timestamp)
    assert_equal(example.randomness, ulid.randomness)
    assert_equal(example.uuidv4, ulid.to_uuidv4(force: true))
    assert_equal(example.to_time, ulid.to_time)
    assert_equal(example.octets, ulid.octets)

    assert do
      ULID.normalized?(example.string)
    end
  end

  def test_from_integer
    EXAMPLES.each do |example|
      ulid = ULID.from_integer(example.integer)
      assert_example(ulid, example)
    end
  end

  def test_parse
    EXAMPLES.each do |example|
      ulid = ULID.parse(example.string)
      assert_example(ulid, example)
    end
  end

  def test_sortable
    ulid_strings = []
    ulid_objects = []
    EXAMPLES.each do |example|
      ulid_strings << example.string
      ulid = ULID.parse(example.string)
      ulid_objects << ulid
    end

    assert_instance_of(ULID, ulid_objects.sample)
    assert_equal(ulid_strings.shuffle.sort, ulid_objects.shuffle.sort.map(&:to_s))
  end

  # ref: https://github.com/kachick/ruby-ulid/pull/341
  def test_from_uuidv4
    irreversible_ulid_to_uuid = {}
    EXAMPLES.each do |example|
      ulid = ULID.from_uuidv4(example.uuidv4)
      assert_equal(example.uuidv4, ulid.to_uuidv4, 'Loading results should be same')
      unless example.string == ulid.to_s
        irreversible_ulid_to_uuid[ulid.to_s] = [example.string, example.uuidv4]
        next
      end
      assert_example(ulid, example)
    end
    irreversible_rate = Rational(irreversible_ulid_to_uuid.size, EXAMPLES.size)
    assert do
      ((9/10r)...1).cover?(irreversible_rate)
    end
    irreversible_ulid_to_uuid.each_value do |original_encoded, _|
      original_ulid = ULID.parse(original_encoded)

      assert_raises(ULID::IrreversibleUUIDError) do
        original_ulid.to_uuidv4
      end

      assert_equal(original_ulid, ULID.from_uuidish(original_ulid.to_uuidish))
    end
  end
end
