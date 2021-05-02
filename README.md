# ruby-ulid

A handy `ULID` library

The `ULID` spec is defined on [ulid/spec](https://github.com/ulid/spec).
This gem aims to provide the generator, monotonic generator, parser and handy manipulation features around the ULID.
Also providing rbs signature files.

---

![ULIDlogo](https://raw.githubusercontent.com/kachick/ruby-ulid/main/logo.png)

![Build Status](https://github.com/kachick/ruby-ulid/actions/workflows/test.yml/badge.svg?branch=main)
[![Gem Version](https://badge.fury.io/rb/ruby-ulid.png)](http://badge.fury.io/rb/ruby-ulid)

## Universally Unique Lexicographically Sortable Identifier

UUID can be suboptimal for many uses-cases because:

- It isn't the most character efficient way of encoding 128 bits of randomness
- UUID v1/v2 is impractical in many environments, as it requires access to a unique, stable MAC address
- UUID v3/v5 requires a unique seed and produces randomly distributed IDs, which can cause fragmentation in many data structures
- UUID v4 provides no other information than randomness which can cause fragmentation in many data structures

Instead, herein is proposed ULID:

- 128-bit compatibility with UUID
- 1.21e+24 unique ULIDs per millisecond
- Lexicographically sortable!
- Canonically encoded as a 26 character string, as opposed to the 36 character UUID
- Uses Crockford's base32 for better efficiency and readability (5 bits per character)
- Case insensitive
- No special characters (URL safe)
- Monotonic sort order (correctly detects and handles the same millisecond)

## Install

```console
$ gem install ruby-ulid
#=> Installed
```

## Usage

The generated `ULID` is an object not just a string.
It means easily get the timestamps and binary formats.

```ruby
require 'ulid'

ulid = ULID.generate #=> ULID(2021-04-27 17:27:22.826 UTC: 01F4A5Y1YAQCYAYCTC7GRMJ9AA)
ulid.to_time #=> 2021-04-27 17:27:22.826 UTC
ulid.to_s #=> "01F4A5Y1YAQCYAYCTC7GRMJ9AA"
ulid.octets #=> [1, 121, 20, 95, 7, 202, 187, 60, 175, 51, 76, 60, 49, 73, 37, 74]
ulid.pattern #=> /(?<timestamp>01F4A5Y1YA)(?<randomness>QCYAYCTC7GRMJ9AA)/i
```

Generator can take `Time` instance

```ruby
time = Time.at(946684800, in: 'UTC') #=> 2000-01-01 00:00:00 UTC
ULID.generate(moment: time) #=> ULID(2000-01-01 00:00:00.000 UTC: 00VHNCZB00N018DCPJA4H9379P)
ULID.generate(moment: time) #=> ULID(2000-01-01 00:00:00.000 UTC: 00VHNCZB006WQT3JTMN0T14EBP)

ulids = 1000.times.map do
  ULID.generate(moment: time)
end
ulids.sort == ulids #=> false

ulids = 1000.times.map do |n|
  ULID.generate(moment: time + n)
end
ulids.sort == ulids #=> true
```

You can parse from exists IDs

FYI: Current parser/validator/matcher implementation aims `strict`, It might be changed in [ulid/spec#57](https://github.com/ulid/spec/pull/57) and [ruby-ulid#57](https://github.com/kachick/ruby-ulid/issues/57).

```ruby
ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') #=> ULID(2016-07-30 23:54:10.259 UTC: 01ARZ3NDEKTSV4RRFFQ69G5FAV)
ulid.to_time #=> 2016-07-30 23:54:10.259 UTC
```

ULIDs are sortable when they are generated in different timestamp with milliseconds precision

```ruby
ulids = 1000.times.map do
  sleep(0.001)
  ULID.generate
end
ulids.sort == ulids #=> true
ulids.uniq(&:to_time).size #=> 1000
```

The basic generator prefers `randomness`, it does not guarantee `sortable` for same milliseconds ULIDs.

```ruby
ulids = 10000.times.map do
  ULID.generate
end
ulids.uniq(&:to_time).size #=> 35 (the size is not fixed, might be changed in environment)
ulids.sort == ulids #=> false
```

If you want to prefer `sortable` rather than the `randomness`, Use `MonotonicGenerator` instead. It is called as [Monotonicity](https://github.com/ulid/spec/tree/d0c7170df4517939e70129b4d6462cc162f2d5bf#monotonicity) on the spec.
(Though it starts with new random value when changed the timestamp)

```ruby
monotonic_generator = ULID::MonotonicGenerator.new
monotonic_ulids = 10000.times.map do
  monotonic_generator.generate
end
sample_ulids_by_the_time = monotonic_ulids.uniq(&:to_time)
sample_ulids_by_the_time.size #=> 32 (the size is not fixed, might be changed in environment)

# In same milliseconds creation, it just increments the end of randomness part
monotonic_ulids.take(5) #=>
# [ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK4),
#  ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK5),
#  ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK6),
#  ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK7),
#  ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK8)]

# When the milliseconds is updated, it starts with new randomness
sample_ulids_by_the_time.take(5) #=>
# [ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK4),
#  ULID(2021-05-02 15:23:48.918 UTC: 01F4PTVCSPF2KXG4ABT7CK3204),
#  ULID(2021-05-02 15:23:48.919 UTC: 01F4PTVCSQF1GERBPCQV6TCX2K),
#  ULID(2021-05-02 15:23:48.920 UTC: 01F4PTVCSRBXN2H4P1EYWZ27AK),
#  ULID(2021-05-02 15:23:48.921 UTC: 01F4PTVCSSK0ASBBZARV7013F8)]

monotonic_ulids.sort == monotonic_ulids #=> true
```

For rough operations, `ULID.scan` might be useful.

```ruby
json =<<'EOD'
{
  "id": "01F4GNAV5ZR6FJQ5SFQC7WDSY3",
  "author": {
    "id": "01F4GNBXW1AM2KWW52PVT3ZY9X",
    "name": "kachick"
  },
  "title": "My awesome blog post",
  "comments": [
    {
      "id": "01F4GNCNC3CH0BCRZBPPDEKBKS",
      "commenter": {
        "id": "01F4GNBXW1AM2KWW52PVT3ZY9X",
        "name": "kachick"
      }
    },
    {
      "id": "01F4GNCXAMXQ1SGBH5XCR6ZH0M",
      "commenter": {
        "id": "01F4GND4RYYSKNAADHQ9BNXAWJ",
        "name": "pankona"
      }
    }
  ]
}
EOD

ULID.scan(json).to_a
#=>
[ULID(2021-04-30 05:51:57.119 UTC: 01F4GNAV5ZR6FJQ5SFQC7WDSY3),
 ULID(2021-04-30 05:52:32.641 UTC: 01F4GNBXW1AM2KWW52PVT3ZY9X),
 ULID(2021-04-30 05:52:56.707 UTC: 01F4GNCNC3CH0BCRZBPPDEKBKS),
 ULID(2021-04-30 05:52:32.641 UTC: 01F4GNBXW1AM2KWW52PVT3ZY9X),
 ULID(2021-04-30 05:53:04.852 UTC: 01F4GNCXAMXQ1SGBH5XCR6ZH0M),
 ULID(2021-04-30 05:53:12.478 UTC: 01F4GND4RYYSKNAADHQ9BNXAWJ)]
```

`ULID.min` and `ULID.max` return termination values for ULID spec.

```ruby
ULID.min #=> ULID(1970-01-01 00:00:00.000 UTC: 00000000000000000000000000)
ULID.max #=> ULID(10889-08-02 05:31:50.655 UTC: 7ZZZZZZZZZZZZZZZZZZZZZZZZZ)

time = Time.at(946684800, Rational('123456.789')).utc #=> 2000-01-01 00:00:00.123456789 UTC
ULID.min(moment: time) #=> ULID(2000-01-01 00:00:00.123 UTC: 00VHNCZB3V0000000000000000)
ULID.max(moment: time) #=> ULID(2000-01-01 00:00:00.123 UTC: 00VHNCZB3VZZZZZZZZZZZZZZZZ)
```

`ULID#next` and `ULID#succ` returns next(successor) ULID

```ruby
ULID.parse('01BX5ZZKBKZZZZZZZZZZZZZZZY').next.to_s #=> "01BX5ZZKBKZZZZZZZZZZZZZZZZ"
ULID.parse('01BX5ZZKBKZZZZZZZZZZZZZZZZ').next.to_s #=> "01BX5ZZKBM0000000000000000"
ULID.parse('7ZZZZZZZZZZZZZZZZZZZZZZZZZ').next #=> nil
```

`ULID#pred` returns predecessor ULID

```ruby
ULID.parse('01BX5ZZKBK0000000000000001').pred.to_s #=> "01BX5ZZKBK0000000000000000"
ULID.parse('01BX5ZZKBK0000000000000000').pred.to_s #=> "01BX5ZZKBJZZZZZZZZZZZZZZZZ"
ULID.parse('00000000000000000000000000').pred #=> nil
```

UUIDv4 converter for migration use-cases. (Of course the timestamp will be useless one. Sortable benefit is lost.)

```ruby
ULID.from_uuidv4('0983d0a2-ff15-4d83-8f37-7dd945b5aa39')
#=> ULID(2301-07-10 00:28:28.821 UTC: 09GF8A5ZRN9P1RYDVXV52VBAHS)
```

## References

- [API documents](https://kachick.github.io/ruby-ulid/)
- [ulid/spec](https://github.com/ulid/spec)
- [Another choices are UUIDv6, UUIDv7, UUIDv8. But they are still in draft state](https://www.ietf.org/archive/id/draft-peabody-dispatch-new-uuid-format-01.html)
