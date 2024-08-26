# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestULIDUseCase < Test::Unit::TestCase
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

    assert_equal(
      [
        ULID.parse('00000000000000000000000000'),
        ULID.parse('0000000000000000000000001A'),
        ULID.parse('0000000000000000000000002M')
      ],
      (ULID.min...).step(42).take(3)
    )
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
    unmarshaled = Marshal.load(dumped)
    assert_not_same(ulid, unmarshaled)
    assert_instance_of(ULID, unmarshaled)
    assert_equal(ulid, unmarshaled)
    assert_equal(ulid.to_i, unmarshaled.to_i)
    assert_equal(ulid.to_s, unmarshaled.to_s)
    assert_equal(ulid.inspect, unmarshaled.inspect)
    assert_equal(ulid.hash, unmarshaled.hash)
    assert_equal(ulid.to_time, unmarshaled.to_time)
    assert_equal(ulid.milliseconds, unmarshaled.milliseconds)
    assert_equal(ulid.entropy, unmarshaled.entropy)
    assert_equal(ulid.timestamp, unmarshaled.timestamp)
    assert_equal(ulid.randomness, unmarshaled.randomness)
    assert_equal(ulid.milliseconds, unmarshaled.milliseconds)
    assert_equal(ulid.octets, unmarshaled.octets)

    # Do not ensure frozen instance behaviors, this tests just check current behavior
    frozen = ULID.sample.freeze
    dumped = Marshal.dump(frozen)
    unmarshaled = Marshal.load(dumped)
    assert_true(unmarshaled.frozen?)
    assert_true(unmarshaled.to_s.frozen?)
  end
end
