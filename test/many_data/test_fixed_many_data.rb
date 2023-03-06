# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')
require_relative('fixtures/example')

# https://github.com/kachick/ruby-ulid/issues/89
class TestFixedManyData < Test::Unit::TestCase
  dump_data = File.binread("#{__dir__}/fixtures/dumped_fixed_examples_2021-05-09_06-22.bin")
  EXAMPLES = Marshal.load(dump_data)

  def assert_example(ulid, example)
    assert do
      example.period.cover?(ulid.to_time)
    end

    assert_equal(example.string, ulid.to_s)
    assert_equal(example.integer, ulid.to_i)
    assert_equal(example.inspect, ulid.inspect)
    assert_equal(example.timestamp, ulid.timestamp)
    assert_equal(example.randomness, ulid.randomness)
    assert_equal(example.uuidv4, ulid.to_uuidv4(ignore_reversible: true))
    assert_equal(example.to_time, ulid.to_time)
    assert_equal(example.octets, ulid.bytes)

    assert do
      ULID.normalized?(example.string)
    end
  end

  def test_many_fixed_examples_for_from_integer
    EXAMPLES.each do |example|
      ulid = ULID.from_integer(example.integer)
      assert_example(ulid, example)
    end
  end

  def test_many_fixed_examples_for_parse
    EXAMPLES.each do |example|
      ulid = ULID.parse(example.string)
      assert_example(ulid, example)
    end
  end

  def test_many_fixed_examples_for_sortable
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

  # @TODO Update with https://github.com/kachick/ruby-ulid/pull/341 direction
  def test_many_fixed_examples_from_uuidv4
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
    puts("#{irreversible_ulid_to_uuid.size}/#{EXAMPLES.size} patterns are not mapping to same ULID. Work in progress https://github.com/kachick/ruby-ulid/issues/76")
    puts('Samples are below', irreversible_ulid_to_uuid.to_a.sample(5).to_h)
  end
end
