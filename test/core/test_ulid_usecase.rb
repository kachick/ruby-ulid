# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestULIDUseCase < Test::Unit::TestCase
  def test_monotonic_generator_with_no_moment_depends_on_current_time
    generator = ULID::MonotonicGenerator.new
    starts_at = Time.now

    ulids = 1000.times.map do |n|
      if (n % 100).zero?
        sleep(0.01)
      end

      generator.generate
    end

    acceptable_period = ULID.floor(starts_at)..(starts_at + 2)

    assert_equal(1000, ulids.map(&:to_s).uniq.size)

    ulids_by_the_time = ulids.group_by(&:to_time)
    sorted_times = ulids_by_the_time.keys
    assert do
      (10..50).cover?(sorted_times.size)
    end

    sorted_times.each_cons(2) do |pred, succ|
      assert do
        (pred.to_i == succ.to_i) || (pred.to_i.succ == succ.to_i)
      end
    end

    # Ensure the incrementing logic
    ulids_by_the_time.each_pair do |time, ulids_in_the_time|
      assert do
        acceptable_period.cover?(time)
      end

      ulids_in_the_time.each_cons(2) do |pred, succ|
        assert do
          pred.to_i.succ == succ.to_i
        end
      end
    end

    sample_ulids_in_different_time = ulids_by_the_time.values.map(&:first)

    # No reasonable basis for this range!
    acceptable_randomness = 42000000..ULID::MAX_ENTROPY

    sample_ulids_in_different_time.each_cons(2) do |pred, succ|
      assert do
        acceptable_randomness.cover?((pred.entropy - succ.entropy).abs)
      end
    end

    assert_equal(ulids, ulids.sort_by(&:to_s))
    assert_equal(ulids, ulids.sort_by(&:to_i))
    assert_equal(ulids, ulids.sort)
  end

  def test_range_elements
    begin_ulid = ULID.generate
    ulid2 = begin_ulid.next
    ulid3 = ulid2.next
    ulid4 = ulid3.next
    ulid5 = ulid4.next
    end_ulid = ulid5.next

    include_end = begin_ulid..end_ulid
    exclude_end = begin_ulid...end_ulid

    assert_equal([begin_ulid, ulid2, ulid3, ulid4, ulid5, end_ulid], include_end.each.to_a)
    assert_equal([begin_ulid, ulid2, ulid3, ulid4, ulid5], exclude_end.each.to_a)

    assert_equal([begin_ulid, ulid3, ulid5], include_end.step(2).to_a)
    assert_equal([begin_ulid, ulid4], include_end.step(3).to_a)
    assert_equal([begin_ulid, end_ulid], include_end.step(5).to_a)
    assert_equal([begin_ulid, ulid3, ulid5], exclude_end.step(2).to_a)
    assert_equal([begin_ulid, ulid4], exclude_end.step(3).to_a)
    assert_equal([begin_ulid], exclude_end.step(5).to_a)
  end

  # https://github.com/kachick/ruby-ulid/issues/47
  def test_filter_ulids_by_time
    time1_1 = Time.at(1, Rational('122999.999'))
    time1_2 = Time.at(1, Rational('123456.789'))
    time1_3 = Time.at(1, Rational('124000.000'))

    time2 = Time.at(2, Rational('123456.789'))

    time3_1 = Time.at(3, Rational('122999.000'))
    time3_2 = Time.at(3, Rational('123456.789'))
    time3_3 = Time.at(3, Rational('123999.999'))
    time3_4 = Time.at(3, Rational('124000.000'))

    time4 = Time.at(4, Rational('123456.789'))

    ulids = [
      _ulid1_1 = ULID.generate(moment: time1_1),
      ulid1_2 = ULID.generate(moment: time1_2),
      ulid1_3 = ULID.generate(moment: time1_3),
      ulid2 = ULID.generate(moment: time2),
      ulid3_1 = ULID.generate(moment: time3_1),
      ulid3_2 = ULID.generate(moment: time3_2),
      ulid3_3 = ULID.generate(moment: time3_3),
      _ulid3_4 = ULID.generate(moment: time3_4),
      _ulid4 = ULID.generate(moment: time4)
    ]

    assert_equal([ulid1_2, ulid1_3, ulid2, ulid3_1, ulid3_2, ulid3_3], ulids.grep(ULID.range(time1_2..time3_2)))
    assert_equal([ulid1_2, ulid1_3, ulid2, ulid3_1], ulids.grep(ULID.range(time1_2...time3_3)))
  end

  def test_marshal_and_unmarshal
    # * Keep basic compatibilities for dumped data in different patch versions since `0.1.6`
    # * Might be changed the behavior in different major/minor versions
    # * Might be changed the behavior in different `Marshal::MAJOR_VERSION` and `Marshal::MINOR_VERSION`
    ulid = ULID.parse('01F6K1RX8VBEA52C9V6CVQ63YK')
    dumped = Marshal.dump(ulid)
    assert_equal((+"U:\tULIDl+\r\xD3\x0Fs73;1Q\x94[\eu\x1C\xA6y\x01").force_encoding(Encoding::ASCII_8BIT), dumped.unpack('c*').slice(2..).pack('c*'))
    unmarshalled = Marshal.load(dumped)
    assert_not_same(ulid, unmarshalled)
    assert_instance_of(ULID, unmarshalled)
    assert_equal(ulid, unmarshalled)
    assert_equal(ulid.to_i, unmarshalled.to_i)
    assert_equal(ulid.to_s, unmarshalled.to_s)
    assert_equal(ulid.inspect, unmarshalled.inspect)
    assert_equal(ulid.hash, unmarshalled.hash)
    assert_equal(ulid.to_time, unmarshalled.to_time)
    assert_equal(ulid.milliseconds, unmarshalled.milliseconds)
    assert_equal(ulid.entropy, unmarshalled.entropy)
    assert_equal(ulid.timestamp, unmarshalled.timestamp)
    assert_equal(ulid.randomness, unmarshalled.randomness)
    assert_equal(ulid.milliseconds, unmarshalled.milliseconds)
    assert_equal(ulid.octets, unmarshalled.octets)
    assert_equal(ulid.patterns, unmarshalled.patterns)

    # Do not ensure frozen instance behaviors, this tests just check current behavior
    frozen = ULID.sample.freeze
    dumped = Marshal.dump(frozen)
    unmarshalled = Marshal.load(dumped)
    assert(!unmarshalled.frozen?)
    assert(unmarshalled.to_s.frozen?)
  end
end
