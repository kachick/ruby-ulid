# coding: utf-8
# frozen_string_literal: true

require_relative '../helper'
require_relative 'fixtures/example'

# https://github.com/kachick/ruby-ulid/issues/89
class TestFixedManyData < Test::Unit::TestCase
  dump_data = File.binread("#{__dir__}/fixtures/dumped_fixed_examples.dat")
  EXAMPLES = Marshal.load(dump_data)

  def assert_example(ulid, example)
    assert_equal(example.string, ulid.to_s)
    assert_equal(example.integer, ulid.to_i)
    assert_equal(example.inspect, ulid.inspect)
    assert_equal(example.timestamp, ulid.timestamp)
    assert_equal(example.randomness, ulid.randomness)
    assert_equal(example.uuidv4, ulid.to_uuidv4)
    assert_equal(example.to_time, ulid.to_time)
    assert_equal(ULID.floor(example.time), ulid.to_time)
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

  # Fix ME!
  def test_many_fixed_examples_from_uuidv4
    non_reversible_ulid_strings = []
    EXAMPLES.each do |example|
      ulid = ULID.from_uuidv4(example.uuidv4)
      unless example.string == ulid.to_s
        non_reversible_ulid_strings << ulid.to_s
        next # found many unexpected cases... :< ref: https://github.com/kachick/ruby-ulid/issues/76
      end
      assert_example(ulid, example)
    end
    puts non_reversible_ulid_strings.size
    puts non_reversible_ulid_strings.take(10)
  end
end
