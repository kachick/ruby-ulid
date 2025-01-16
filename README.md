# ruby-ulid

[![Build Status](https://github.com/kachick/ruby-ulid/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/kachick/ruby-ulid/actions/workflows/ci.yml?query=branch%3Amain)
[![Gem Version](https://badge.fury.io/rb/ruby-ulid.svg)](http://badge.fury.io/rb/ruby-ulid)

This gem is in maintenance mode, I have no plan to add new features.\
The reason is UUID v7 has been accepted in [IETF](https://www.rfc-editor.org/rfc/rfc9562.html) and [ruby's securerandom](https://github.com/ruby/securerandom/pull/19). See [UUID section](#uuid) for detail.

## Overview

[ulid/spec](https://github.com/ulid/spec) defines some useful features.\
In particular, it has uniqueness, randomness, extractable timestamps, and sortability.\
This gem aims to provide the generator, optional monotonicity, parser, and other manipulations around ULID.\
[RBS](https://github.com/ruby/rbs) definitions are also included.

---

![ULIDlogo](./assets/logo.png)

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
- Uses [Crockford's base32](https://www.crockford.com/base32.html) for better efficiency and readability (5 bits per character)
- Case insensitive
- No special characters (URL safe)
- Monotonic sort order (correctly detects and handles the same millisecond)

## Usage

### Install

Tested only in the last 2 Rubies. So you need Ruby 3.3 or higher.

Add this line to your `Gemfile`.

```ruby
gem('ruby-ulid', '~> 0.9.0')
```

And load it.

```ruby
require 'ulid'
```

NOTE: This README contains information about the development version.\
If you would like to see released version's one. [Look at the ref](https://github.com/kachick/ruby-ulid/tree/v0.9.0).

In [Nix](https://nixos.org/), you can skip the installation steps for both ruby and ruby-ulid to try.

```console
> nix run github:kachick/ruby-ulid#ruby -- -e 'p ULID.generate'
ULID(2024-03-03 18:37:06.152 UTC: 01HR2SNY789ZZ027EDJEHAGQ62)

> nix run github:kachick/ruby-ulid#irb
irb(main):001:0> ULID.parse('01H66XG2A9WWYRCYGPA62T4AZA')
=> ULID(2023-07-25 16:18:12.937 UTC: 01H66XG2A9WWYRCYGPA62T4AZA)
```

### Generator and Parser

`ULID.generate` returns `ULID` instance. It is not just a string.

```ruby
ulid = ULID.generate #=> ULID(2021-04-27 17:27:22.826 UTC: 01F4A5Y1YAQCYAYCTC7GRMJ9AA)
```

`ULID.parse` returns `ULID` instance from exists encoded ULIDs.

```ruby
ulid = ULID.parse('01F4A5Y1YAQCYAYCTC7GRMJ9AA') #=> ULID(2021-04-27 17:27:22.826 UTC: 01F4A5Y1YAQCYAYCTC7GRMJ9AA)
```

It has inspector methods.

```ruby
ulid.to_time #=> 2021-04-27 17:27:22.826 UTC
ulid.milliseconds #=> 1619544442826
ulid.encode #=> "01F4A5Y1YAQCYAYCTC7GRMJ9AA"
ulid.to_s #=> "01F4A5Y1YAQCYAYCTC7GRMJ9AA"
ulid.timestamp #=> "01F4A5Y1YA"
ulid.randomness #=> "QCYAYCTC7GRMJ9AA"
ulid.to_i #=> 1957909092946624190749577070267409738
ulid.octets #=> [1, 121, 20, 95, 7, 202, 187, 60, 175, 51, 76, 60, 49, 73, 37, 74]
```

`ULID.generate` can take fixed `Time` instance. `ULID.at` is the shorthand.

```ruby
time = Time.at(946684800).utc #=> 2000-01-01 00:00:00 UTC
ULID.generate(moment: time) #=> ULID(2000-01-01 00:00:00.000 UTC: 00VHNCZB00N018DCPJA4H9379P)
ULID.generate(moment: time) #=> ULID(2000-01-01 00:00:00.000 UTC: 00VHNCZB006WQT3JTMN0T14EBP)
ULID.at(time) #=> ULID(2000-01-01 00:00:00.000 UTC: 00VHNCZB002W5BGWWKN76N22H6)
```

Also `ULID.encode` and `ULID.decode_time` can be used to get primitive values for most usecases.

`ULID.encode` returns [normalized](#variants-of-format) String without ULID object creation.\
It can take same arguments as `ULID.generate`.

```ruby
ULID.encode #=> "01G86M42Q6SJ9XQM2ZRM6JRDSF"
ULID.encode(moment: Time.at(946684800).utc) #=> "00VHNCZB00SYG7RCEXZC9DA4E1"
```

`ULID.decode_time` returns Time. It can take `in` keyarg as same as `Time.at`.

```ruby
ULID.decode_time('00VHNCZB00SYG7RCEXZC9DA4E1') #=> 2000-01-01 00:00:00 UTC
ULID.decode_time('00VHNCZB00SYG7RCEXZC9DA4E1', in: '+09:00') #=> 2000-01-01 09:00:00 +0900
```

This project does not prioritize on the speed. However it actually works faster than others! :zap:

Snapshot on v0.8.0 with Ruby 3.2.1 is below

- Generator is 1.9x faster than - [ulid gem - v1.4.0](https://github.com/rafaelsales/ulid)
- Generator is 2.0x faster than - [ulid-ruby gem - v1.0.2](https://github.com/abachman/ulid-ruby)
- Parser is 3.1x faster than - [ulid-ruby gem - v1.0.2](https://github.com/abachman/ulid-ruby)

You can see further detail at [Benchmark](https://github.com/kachick/ruby-ulid/wiki/Benchmark).

### Sortable by timestamp

ULIDs are sortable when they are generated in different timestamp with milliseconds precision.

```ruby
ulids = 1000.times.map do
  sleep(0.001)
  ULID.generate
end
ulids.uniq(&:to_time).size #=> 1000
ulids.sort == ulids #=> true
```

The basic generator prefers `randomness`, the results in the same milliseconds are not sortable.

```ruby
ulids = 10000.times.map do
  ULID.generate
end
ulids.uniq(&:to_time).size #=> 35 (the size is not fixed, might be changed in environment)
ulids.sort == ulids #=> false
```

### How to keep `Sortable` even if in same timestamp

If you prefer `sortability`, you can use `MonotonicGenerator` instead.\
It is referred to as [Monotonicity](https://github.com/ulid/spec/tree/d0c7170df4517939e70129b4d6462cc162f2d5bf#monotonicity) in the spec.\
(Although it starts with a new random value when the timestamp is changed)

```ruby
monotonic_generator = ULID::MonotonicGenerator.new
ulids = 10000.times.map do
  monotonic_generator.generate
end
sample_ulids_by_the_time = ulids.uniq(&:to_time)
sample_ulids_by_the_time.size #=> 32 (the size is not fixed, might be changed in environment)

# In same milliseconds creation, it just increments the end of randomness part
ulids.take(3) #=>
# [ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK4),
#  ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK5),
#  ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK6)]

# When the milliseconds is updated, it starts with new randomness
sample_ulids_by_the_time.take(3) #=>
# [ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK4),
#  ULID(2021-05-02 15:23:48.918 UTC: 01F4PTVCSPF2KXG4ABT7CK3204),
#  ULID(2021-05-02 15:23:48.919 UTC: 01F4PTVCSQF1GERBPCQV6TCX2K)]

ulids.sort == ulids #=> true
```

Same instance of `ULID::MonotonicGenerator` does not generate duplicated ULIDs even in multi threads environment. It is implemented with [Monitor](https://bugs.ruby-lang.org/issues/16255).

### Filtering IDs with `Time`

`ULID` can be element of the `Range`. If they were generated with monotonic generator, ID based filtering is easy and reliable.

```ruby
include_end = ulid1..ulid2
exclude_end = ulid1...ulid2

ulids.grep(one_of_the_above)
ulids.grep_v(one_of_the_above)
```

When want to filter ULIDs with `Time`, we should consider to handle the precision.\
So this gem provides `ULID.range` to generate reasonable `Range[ULID]` from `Range[Time]`

```ruby
# Both of below, The begin of `Range[ULID]` will be the minimum in the floored milliseconds of the time1
include_end = ULID.range(time1..time2) #=> The end of `Range[ULID]` will be the maximum in the floored milliseconds of the time2
exclude_end = ULID.range(time1...time2) #=> The end of `Range[ULID]` will be the minimum in the floored milliseconds of the time2

# Below patterns are acceptable
pinpointing = ULID.range(time1..time1) #=> This will match only for all IDs in `time1`
until_the_end = ULID.range(..time1) #=> This will match only for all IDs upto `time1`
until_the_ulid_limit = ULID.range(time1..) # This will match only for all IDs from `time1` to max value of the ULID limit

# So you can use the generated range objects as below
ulids.grep(one_of_the_above)
ulids.grep_v(one_of_the_above)
#=> I hope the results should be actually you want!
```

If you want to manually handle the Time objects, `ULID.floor` returns new `Time` with truncating excess precisions in ULID spec.

```ruby
time = Time.at(946684800, Rational('123456.789')).utc #=> 2000-01-01 00:00:00.123456789 UTC
ULID.floor(time) #=> 2000-01-01 00:00:00.123 UTC
```

### Tools

#### Scanner for string (e.g. `JSON`)

For rough operations, `ULID.scan` might be useful.

```ruby
json = <<'JSON'
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
JSON

ULID.scan(json).to_a
#=>
# [ULID(2021-04-30 05:51:57.119 UTC: 01F4GNAV5ZR6FJQ5SFQC7WDSY3),
#  ULID(2021-04-30 05:52:32.641 UTC: 01F4GNBXW1AM2KWW52PVT3ZY9X),
#  ULID(2021-04-30 05:52:56.707 UTC: 01F4GNCNC3CH0BCRZBPPDEKBKS),
#  ULID(2021-04-30 05:52:32.641 UTC: 01F4GNBXW1AM2KWW52PVT3ZY9X),
#  ULID(2021-04-30 05:53:04.852 UTC: 01F4GNCXAMXQ1SGBH5XCR6ZH0M),
#  ULID(2021-04-30 05:53:12.478 UTC: 01F4GND4RYYSKNAADHQ9BNXAWJ)]
```

#### Get boundary ULIDs

`ULID.min` and `ULID.max` return termination values for ULID spec.

It can take `Time` instance as an optional argument. Then returns min/max ID that has limit of randomness part in the time.

```ruby
ULID.min #=> ULID(1970-01-01 00:00:00.000 UTC: 00000000000000000000000000)
ULID.max #=> ULID(10889-08-02 05:31:50.655 UTC: 7ZZZZZZZZZZZZZZZZZZZZZZZZZ)

time = Time.at(946684800, Rational('123456.789')).utc #=> 2000-01-01 00:00:00.123456789 UTC
ULID.min(time) #=> ULID(2000-01-01 00:00:00.123 UTC: 00VHNCZB3V0000000000000000)
ULID.max(time) #=> ULID(2000-01-01 00:00:00.123 UTC: 00VHNCZB3VZZZZZZZZZZZZZZZZ)
```

#### As an element in Enumerable and Range

`ULID#next` and `ULID#succ` returns next(successor) ULID.\
Especially `ULID#succ` makes it possible `Range[ULID]#each`.

NOTE: However basically `Range[ULID]#each` should not be used. Incrementing 128 bits IDs are not reasonable operation in most cases.

```ruby
ULID.parse('01BX5ZZKBKZZZZZZZZZZZZZZZY').next.to_s #=> "01BX5ZZKBKZZZZZZZZZZZZZZZZ"
ULID.parse('01BX5ZZKBKZZZZZZZZZZZZZZZZ').next.to_s #=> "01BX5ZZKBM0000000000000000"
ULID.parse('7ZZZZZZZZZZZZZZZZZZZZZZZZZ').next #=> nil
```

`ULID#pred` returns predecessor ULID.

```ruby
ULID.parse('01BX5ZZKBK0000000000000001').pred.to_s #=> "01BX5ZZKBK0000000000000000"
ULID.parse('01BX5ZZKBK0000000000000000').pred.to_s #=> "01BX5ZZKBJZZZZZZZZZZZZZZZZ"
ULID.parse('00000000000000000000000000').pred #=> nil
```

`ULID#+` is also provided to realize `Range#step` since [ruby-3.4.0 spec changes](https://bugs.ruby-lang.org/issues/18368).

```ruby
# This code works only in ruby-3.4.0dev or later
(ULID.min...).step(42).take(3)
# =>
[ULID(1970-01-01 00:00:00.000 UTC: 00000000000000000000000000),
 ULID(1970-01-01 00:00:00.000 UTC: 0000000000000000000000001A),
 ULID(1970-01-01 00:00:00.000 UTC: 0000000000000000000000002M)]
```

#### Test helpers

`ULID.sample` returns random ULIDs.

Basically ignores generating time.

```ruby
ULID.sample #=> ULID(2545-07-26 06:51:20.085 UTC: 0GGKQ45GMNMZR6N8A8GFG0ZXST)
ULID.sample #=> ULID(5098-07-26 21:31:06.946 UTC: 2SSBNGGYA272J7BMDCG4Z6EEM5)
ULID.sample(0) #=> []
ULID.sample(1) #=> [ULID(2241-04-16 03:31:18.440 UTC: 07S52YWZ98AZ8T565MD9VRYMQH)]
ULID.sample(3)
#=>
#[ULID(5701-04-29 12:41:19.647 UTC: 3B2YH2DV0ZYDDATGTYSKMM1CMT),
# ULID(2816-08-01 01:21:46.612 UTC: 0R9GT6RZKMK3RG02Q2HAFVKEY2),
# ULID(10408-10-05 17:06:27.848 UTC: 7J6CPTEEC86Y24EQ4F1Y93YYN0)]
```

You can specify a range object for the timestamp restriction, see also `ULID.range`.

```ruby
ulid1 = ULID.parse('01F4A5Y1YAQCYAYCTC7GRMJ9AA') #=> ULID(2021-04-27 17:27:22.826 UTC: 01F4A5Y1YAQCYAYCTC7GRMJ9AA)
ulid2 = ULID.parse('01F4PTVCSN9ZPFKYTY2DDJVRK4') #=> ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK4)
ulids = ULID.sample(3, period: ulid1..ulid2)
#=>
#[ULID(2021-05-02 06:57:19.954 UTC: 01F4NXW02JNB8H0J0TK48JD39X),
# ULID(2021-05-02 07:06:07.458 UTC: 01F4NYC372GVP7NS0YAYQGT4VZ),
# ULID(2021-05-01 06:16:35.791 UTC: 01F4K94P6F6P68K0H64WRDSFKW)]
ULID.sample(3, period: ulid1.to_time..ulid2.to_time)
#=>
# [ULID(2021-04-29 06:44:41.513 UTC: 01F4E5YPD9XQ3MYXWK8ZJKY8SW),
#  ULID(2021-05-01 00:35:06.629 UTC: 01F4JNKD85SVK1EAEYSJGF53A2),
#  ULID(2021-05-02 12:45:28.408 UTC: 01F4PHSEYRG9BWBEWMRW1XE6WW)]
```

#### Variants of format

I'm afraid so, we should consider [Current ULID spec](https://github.com/ulid/spec/tree/d0c7170df4517939e70129b4d6462cc162f2d5bf#universally-unique-lexicographically-sortable-identifier) has `orthographical variants of the format` possibilities.

> Case insensitive

I can understand it might be considered in actual use-case. So `ULID.parse` accepts upcase and downcase.\
However it is a controversial point, discussing in [ulid/spec#3](https://github.com/ulid/spec/issues/3).

> Uses Crockford's base32 for better efficiency and readability (5 bits per character)

The original `Crockford's base32` maps `I`, `L` to `1`, `O` to `0`.\
And accepts freestyle inserting `Hyphens (-)`.\
To consider this patterns or not is different in each implementations.

I have suggested to clarify `subset of Crockford's base32` in [ulid/spec#57](https://github.com/ulid/spec/pull/57).

This gem provides some methods to handle the nasty possibilities.

`ULID.normalize`, `ULID.normalized?`, `ULID.valid_as_variant_format?` and `ULID.parse_variant_format`

```ruby
ULID.normalize('01g70y0y7g-z1xwdarexergsddd') #=> "01G70Y0Y7GZ1XWDAREXERGSDDD"
ULID.normalized?('01g70y0y7g-z1xwdarexergsddd') #=> false
ULID.normalized?('01G70Y0Y7GZ1XWDAREXERGSDDD') #=> true
ULID.valid_as_variant_format?('01g70y0y7g-z1xwdarexergsddd') #=> true
ULID.parse_variant_format('01G70Y0Y7G-ZLXWDIREXERGSDoD') #=> ULID(2022-07-03 02:25:22.672 UTC: 01G70Y0Y7GZ1XWD1REXERGSD0D)
```

#### UUID

Both ULID and UUID are 128-bit IDs. But with different specs. Especially, UUID has some versions, for example, UUIDv4 and UUIDv7.

All UUIDs can be converted to ULID, but only [new versions](https://datatracker.ietf.org/doc/rfc9562/) have a correct "timestamp".\
Most ULIDs cannot be converted to UUID while maintaining reversibility, because UUID requires version and variants in the fields.

See also [ulid/spec#64](https://github.com/ulid/spec/issues/64) for further detail.

For now, this gem provides some methods for UUIDs.

- Reversibility is preferred: `ULID.from_uuidish`, `ULID.to_uuidish`
- Prefer variants specification: `ULID.from_uuid_v4`, `ULID.from_uuid_v7`, `ULID.to_uuid_v4`, `ULID.to_uuid_v7`

```ruby
# All UUIDv4 and UUIDv7 IDs can be reversible even if converted to ULID
uuid_v4 = SecureRandom.uuid_v4
ULID.from_uuidish(uuid_v4) == ULID.from_uuid_v4(uuid_v4) #=> true
ULID.from_uuidish(uuid_v4).to_uuidish == ULID.from_uuid_v4(uuid_v4).to_uuid_v4 #=> true

# v4 does not have timestamp, v7 has it.

ULID.from_uuid_v4(SecureRandom.uuid_v4).to_time
# 'f80b3f53-043a-4298-a674-cd83a7fd5d22' => 10612-05-19 16:58:53.882 UTC

ULID.from_uuid_v7(SecureRandom.uuid_v7).to_time
# '01946f9e-bf58-7be3-8fd4-4606606b05aa' => 2025-01-16 14:57:42.232 UTC
# ULID is officially defined milliseconds precision for the spec. So omit the nanoseconds precisions even if the UUID v7 ID was generated with extra_timestamp_bits >= 1.

# However most ULIDs cannot be converted to versioned UUID
ulid = ULID.parse('01F4A5Y1YAQCYAYCTC7GRMJ9AA')
ulid.to_uuid_v4 #=> ULID::IrreversibleUUIDError
# So 2 ways to get substitute strings that might satisfy the use case
ulid.to_uuid_v4(force: true) #=> "0179145f-07ca-4b3c-af33-4c3c3149254a" this cannot be reverse to source ULID
ulid == ULID.from_uuid_v4(ulid.to_uuid_v4(force: true)) #=> false
ulid.to_uuidish #=> "0179145f-07ca-bb3c-af33-4c3c3149254a" does not satisfy UUIDv4 spec
ulid == ULID.from_uuidish(ulid.to_uuidish) #=> true

# Seeing boundary IDs makes it easier to understand
ULID.min.to_uuidish #=> "00000000-0000-0000-0000-000000000000"
ULID.min.to_uuid_v4(force: true) #=> "00000000-0000-4000-8000-000000000000"
ULID.max.to_uuidish #=> "ffffffff-ffff-ffff-ffff-ffffffffffff"
ULID.max.to_uuid_v4(force: true) #=> "ffffffff-ffff-4fff-bfff-ffffffffffff"
```

## Migration from other gems

See [wiki page for gem migration](https://github.com/kachick/ruby-ulid/wiki/Gem-migration).

## RBS

- Try at [examples/rbs_sandbox](https://github.com/kachick/ruby-ulid/tree/main/examples/rbs_sandbox).
- See the overview in [our wiki page for RBS](https://github.com/kachick/ruby-ulid/wiki/RBS)

## References

- [Repository](https://github.com/kachick/ruby-ulid)
- [API documents](https://kachick.github.io/ruby-ulid/)
- [ulid/spec](https://github.com/ulid/spec)
