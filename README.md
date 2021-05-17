# ruby-ulid

## Overview

The `ULID` spec is defined on [ulid/spec](https://github.com/ulid/spec). It has useful specs for applications (e.g. `Database key`), especially possess all `uniqueness`, `randomness`, `extractable timestamps` and `sortable` features.
This gem aims to provide the generator, monotonic generator, parser and handy manipulation features around the ULID.
Also providing [ruby/rbs](https://github.com/ruby/rbs) signature files.

---

![ULIDlogo](https://raw.githubusercontent.com/kachick/ruby-ulid/main/logo.png)

![Build Status](https://github.com/kachick/ruby-ulid/actions/workflows/test_behaviors.yml/badge.svg?branch=main)
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
- Uses [Crockford's base32](https://www.crockford.com/base32.html) for better efficiency and readability (5 bits per character)
- Case insensitive
- No special characters (URL safe)
- Monotonic sort order (correctly detects and handles the same millisecond)

## Usage

### Install

Require Ruby 2.6 or later

This command will install the latest version into your environment

```console
$ gem install ruby-ulid
Should be installed!
```

Add this line to your application/library's `Gemfile` is needed in basic use-case

```ruby
gem 'ruby-ulid', '>= 0.1.3', '< 0.2.0'
```

### Generator and Parser

The generated `ULID` is an object not just a string.
It means easily get the timestamps and binary formats.

```ruby
require 'ulid'

ulid = ULID.generate #=> ULID(2021-04-27 17:27:22.826 UTC: 01F4A5Y1YAQCYAYCTC7GRMJ9AA)
ulid.to_time #=> 2021-04-27 17:27:22.826 UTC
ulid.milliseconds #=> 1619544442826
ulid.to_s #=> "01F4A5Y1YAQCYAYCTC7GRMJ9AA"
ulid.timestamp #=> "01F4A5Y1YA"
ulid.randomness #=> "QCYAYCTC7GRMJ9AA"
ulid.to_i #=> 1957909092946624190749577070267409738
ulid.octets #=> [1, 121, 20, 95, 7, 202, 187, 60, 175, 51, 76, 60, 49, 73, 37, 74]
```

You can get the objects from exists encoded ULIDs

```ruby
ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') #=> ULID(2016-07-30 23:54:10.259 UTC: 01ARZ3NDEKTSV4RRFFQ69G5FAV)
ulid.to_time #=> 2016-07-30 23:54:10.259 UTC
```

### Sortable with the timestamp

ULIDs are sortable when they are generated in different timestamp with milliseconds precision

```ruby
ulids = 1000.times.map do
  sleep(0.001)
  ULID.generate
end
ulids.uniq(&:to_time).size #=> 1000
ulids.sort == ulids #=> true
```

`ULID.generate` can take fixed `Time` instance. The shorthand is `ULID.at`

```ruby
time = Time.at(946684800).utc #=> 2000-01-01 00:00:00 UTC
ULID.generate(moment: time) #=> ULID(2000-01-01 00:00:00.000 UTC: 00VHNCZB00N018DCPJA4H9379P)
ULID.generate(moment: time) #=> ULID(2000-01-01 00:00:00.000 UTC: 00VHNCZB006WQT3JTMN0T14EBP)
ULID.at(time) #=> ULID(2000-01-01 00:00:00.000 UTC: 00VHNCZB002W5BGWWKN76N22H6)

ulids = 1000.times.map do |n|
  ULID.at(time + n)
end
ulids.sort == ulids #=> true
```

The basic generator prefers `randomness`, it does not guarantee `sortable` for same milliseconds ULIDs.

```ruby
ulids = 10000.times.map do
  ULID.generate
end
ulids.uniq(&:to_time).size #=> 35 (the size is not fixed, might be changed in environment)
ulids.sort == ulids #=> false
```

### How to keep `Sortable` even if in same timestamp

If you want to prefer `sortable`, Use `MonotonicGenerator` instead. It is called as [Monotonicity](https://github.com/ulid/spec/tree/d0c7170df4517939e70129b4d6462cc162f2d5bf#monotonicity) on the spec.
(Though it starts with new random value when changed the timestamp)

```ruby
monotonic_generator = ULID::MonotonicGenerator.new
ulids = 10000.times.map do
  monotonic_generator.generate
end
sample_ulids_by_the_time = ulids.uniq(&:to_time)
sample_ulids_by_the_time.size #=> 32 (the size is not fixed, might be changed in environment)

# In same milliseconds creation, it just increments the end of randomness part
ulids.take(5) #=>
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

ulids.sort == ulids #=> true
```

Same generator does not generate duplicated ULIDs even in multi threads environment. It is implemented with [Monitor](https://bugs.ruby-lang.org/issues/16255)

### Filtering IDs with `Time`

`ULID` can be element of the `Range`. If you generated the IDs in monotonic generator, ID based filtering is easy and reliable

```ruby
include_end = ulid1..ulid2
exclude_end = ulid1...ulid2

ulids.grep(one_of_the_above)
ulids.grep_v(one_of_the_above)
```

When want to filter ULIDs with `Time`, we should consider to handle the precision.
So this gem provides `ULID.range` to generate reasonable `Range[ULID]` from `Range[Time]`

```ruby
# Both of below, The begin of `Range[ULID]` will be the minimum in the floored milliseconds of the time1
include_end = ULID.range(time1..time2) #=> The end of `Range[ULID]` will be the maximum in the floored milliseconds of the time2
exclude_end = ULID.range(time1...time2) #=> The end of `Range[ULID]` will be the minimum in the floored milliseconds of the time2

# Below patterns are acceptable
pinpointing = ULID.range(time1..time1) #=> This will match only for all IDs in `time1`
# until_the_end = ULID.range(..time1) #=> This will match only for all IDs upto `time1` (The `nil` starting `Range` can be used since Ruby 2.7)
until_the_end = ULID.range(ULID.min.to_time..time1) #=> This is same as above for Ruby 2.6
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

### Scanner for string (e.g. `JSON`)

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
# [ULID(2021-04-30 05:51:57.119 UTC: 01F4GNAV5ZR6FJQ5SFQC7WDSY3),
#  ULID(2021-04-30 05:52:32.641 UTC: 01F4GNBXW1AM2KWW52PVT3ZY9X),
#  ULID(2021-04-30 05:52:56.707 UTC: 01F4GNCNC3CH0BCRZBPPDEKBKS),
#  ULID(2021-04-30 05:52:32.641 UTC: 01F4GNBXW1AM2KWW52PVT3ZY9X),
#  ULID(2021-04-30 05:53:04.852 UTC: 01F4GNCXAMXQ1SGBH5XCR6ZH0M),
#  ULID(2021-04-30 05:53:12.478 UTC: 01F4GND4RYYSKNAADHQ9BNXAWJ)]
```

`ULID#patterns` is a util for text based operations.
The results and spec are not fixed. Should not be used except snippets/console operation

```ruby
ULID.parse('01F4GNBXW1AM2KWW52PVT3ZY9X').patterns
#=> returns like a fallowing Hash
{
  named_captures: /(?<timestamp>01F4GNBXW1)(?<randomness>AM2KWW52PVT3ZY9X)/i,
  strict_named_captures: /\A(?<timestamp>01F4GNBXW1)(?<randomness>AM2KWW52PVT3ZY9X)\z/i
}
```

### Some methods to help manipulations

`ULID.min` and `ULID.max` return termination values for ULID spec.

It can take `Time` instance as an optional argument. Then returns min/max ID that has limit of randomness part in the time.

```ruby
ULID.min #=> ULID(1970-01-01 00:00:00.000 UTC: 00000000000000000000000000)
ULID.max #=> ULID(10889-08-02 05:31:50.655 UTC: 7ZZZZZZZZZZZZZZZZZZZZZZZZZ)

time = Time.at(946684800, Rational('123456.789')).utc #=> 2000-01-01 00:00:00.123456789 UTC
ULID.min(time) #=> ULID(2000-01-01 00:00:00.123 UTC: 00VHNCZB3V0000000000000000)
ULID.max(time) #=> ULID(2000-01-01 00:00:00.123 UTC: 00VHNCZB3VZZZZZZZZZZZZZZZZ)
```

`ULID#next` and `ULID#succ` returns next(successor) ULID.
Especially `ULID#succ` makes it possible `Range[ULID]#each`.

NOTE: But basically `Range[ULID]#each` should not be used, incrementing 128 bits IDs are not reasonable operation in most case

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

`ULID.sample` returns random ULIDs.

Basically ignores generating time.

```ruby
ULID.sample #=> ULID(2545-07-26 06:51:20.085 UTC: 0GGKQ45GMNMZR6N8A8GFG0ZXST)
ULID.sample #=> ULID(5098-07-26 21:31:06.946 UTC: 2SSBNGGYA272J7BMDCG4Z6EEM5)
ULID.sample(0) #=> []
ULID.sample(1) #=> [ULID(2241-04-16 03:31:18.440 UTC: 07S52YWZ98AZ8T565MD9VRYMQH)]
ULID.sample(5)
#=>
#[ULID(5701-04-29 12:41:19.647 UTC: 3B2YH2DV0ZYDDATGTYSKMM1CMT),
# ULID(2816-08-01 01:21:46.612 UTC: 0R9GT6RZKMK3RG02Q2HAFVKEY2),
# ULID(10408-10-05 17:06:27.848 UTC: 7J6CPTEEC86Y24EQ4F1Y93YYN0),
# ULID(2741-09-02 16:24:18.803 UTC: 0P4Q4V34KKAJW46QW47WQB5463),
# ULID(2665-03-16 14:50:22.724 UTC: 0KYFW9DWM4CEGFNTAC6YFAVVJ6)]
```

You can specify a range object for the timestamp restriction, see also `ULID.range`.

```ruby
ulid1 = ULID.parse('01F4A5Y1YAQCYAYCTC7GRMJ9AA') #=> ULID(2021-04-27 17:27:22.826 UTC: 01F4A5Y1YAQCYAYCTC7GRMJ9AA)
ulid2 = ULID.parse('01F4PTVCSN9ZPFKYTY2DDJVRK4') #=> ULID(2021-05-02 15:23:48.917 UTC: 01F4PTVCSN9ZPFKYTY2DDJVRK4)
ulids = ULID.sample(1000, period: ulid1..ulid2)
ulids.uniq.size #=> 1000
ulids.take(10)
#=>
#[ULID(2021-05-02 06:57:19.954 UTC: 01F4NXW02JNB8H0J0TK48JD39X),
# ULID(2021-05-02 07:06:07.458 UTC: 01F4NYC372GVP7NS0YAYQGT4VZ),
# ULID(2021-05-01 06:16:35.791 UTC: 01F4K94P6F6P68K0H64WRDSFKW),
# ULID(2021-04-27 22:17:37.844 UTC: 01F4APHGSMFJZQTGXKZBFFBPJP),
# ULID(2021-04-28 20:17:55.357 UTC: 01F4D231MXQJXAR8G2JZHEJNH3),
# ULID(2021-04-30 07:18:54.307 UTC: 01F4GTA2332AS2VPHC4FMKC7R5),
# ULID(2021-05-02 12:26:03.480 UTC: 01F4PGNXARG554Y3HYVBDW4T9S),
# ULID(2021-04-29 09:52:15.107 UTC: 01F4EGP483ZX2747FQPWQNPPMW),
# ULID(2021-04-29 03:18:24.152 UTC: 01F4DT4Z4RA0QV8WFQGRAG63EH),
# ULID(2021-05-02 13:27:16.394 UTC: 01F4PM605ABF5SDVMEHBH8JJ9R)]
ULID.sample(10, period: ulid1.to_time..ulid2.to_time)
#=>
# [ULID(2021-04-29 06:44:41.513 UTC: 01F4E5YPD9XQ3MYXWK8ZJKY8SW),
#  ULID(2021-05-01 00:35:06.629 UTC: 01F4JNKD85SVK1EAEYSJGF53A2),
#  ULID(2021-05-02 12:45:28.408 UTC: 01F4PHSEYRG9BWBEWMRW1XE6WW),
#  ULID(2021-05-01 03:06:09.130 UTC: 01F4JY7ZBABCBMX16XH2Q4JW4W),
#  ULID(2021-04-29 21:38:58.109 UTC: 01F4FS45DX4049JEQK4W6TER6G),
#  ULID(2021-04-29 17:14:14.116 UTC: 01F4F9ZDQ449BE8BBZFEHYQWG2),
#  ULID(2021-04-30 16:18:08.205 UTC: 01F4HS5DPD1HWDVJNJ6YKJXKSK),
#  ULID(2021-04-30 10:31:33.602 UTC: 01F4H5ATF2A1CSQF0XV5NKZ288),
#  ULID(2021-04-28 16:49:06.484 UTC: 01F4CP4PDM214Q6H3KJP7DYJRR),
#  ULID(2021-04-28 15:05:06.808 UTC: 01F4CG68ZRST94T056KRZ5K9S4)]
```

### ULID specification ambiguity around orthographical variants of the format

I'm afraid so, we should consider [Current ULID spec](https://github.com/ulid/spec/tree/d0c7170df4517939e70129b4d6462cc162f2d5bf#universally-unique-lexicographically-sortable-identifier) has `orthographical variants of the format` possibilities.

>Uses Crockford's base32 for better efficiency and readability (5 bits per character)

The original `Crockford's base32` maps `I`, `L` to `1`, `O` to `0`.
And accepts freestyle inserting `Hyphens (-)`.
To consider this patterns or not is different in each implementations.

Current parser/validator/matcher aims to cover `subset of Crockford's base32`.
I have suggested it would be clarified in [ulid/spec#57](https://github.com/ulid/spec/pull/57).

>Case insensitive

I can understand it might be considered in actual use-case.
But it is a controversial point, discussing in [ulid/spec#3](https://github.com/ulid/spec/issues/3).

Be that as it may, this gem provides API for handling the nasty possibilities.

`ULID.normalize` and `ULID.normalized?`

```ruby
ULID.normalize('-olarz3-noekisv4rrff-q6ig5fav--') #=> "01ARZ3N0EK1SV4RRFFQ61G5FAV"
ULID.normalized?('-olarz3-noekisv4rrff-q6ig5fav--') #=> false
ULID.normalized?('01ARZ3N0EK1SV4RRFFQ61G5FAV') #=> true
```

### UUIDv4 converter for migration use-cases

`ULID.from_uuidv4` and `ULID#to_uuidv4` is the converter.
The imported timestamp is meaningless. So ULID's benefit will lost.

```ruby
# Currently experimental feature, so needed to load the extension.
require 'ulid/uuid'

# Basically reversible
ulid = ULID.from_uuidv4('0983d0a2-ff15-4d83-8f37-7dd945b5aa39') #=> ULID(2301-07-10 00:28:28.821 UTC: 09GF8A5ZRN9P1RYDVXV52VBAHS)
ulid.to_uuidv4 #=> "0983d0a2-ff15-4d83-8f37-7dd945b5aa39"

uuid_v4s = 10000.times.map { SecureRandom.uuid }
uuid_v4s.uniq.size == 10000 #=> Probably `true`

ulids = uuid_v4s.map { |uuid_v4| ULID.from_uuidv4(uuid_v4) }
ulids.map(&:to_uuidv4) == uuid_v4s #=> **Probably** `true` except below examples.

# NOTE: Some boundary values are not reversible. See below.

ULID.min.to_uuidv4 #=> "00000000-0000-4000-8000-000000000000"
ULID.max.to_uuidv4 #=> "ffffffff-ffff-4fff-bfff-ffffffffffff"

# These importing results are same as https://github.com/ahawker/ulid/tree/96bdb1daad7ce96f6db8c91ac0410b66d2e1c4c1 on CPython 3.9.4
reversed_min = ULID.from_uuidv4('00000000-0000-4000-8000-000000000000') #=> ULID(1970-01-01 00:00:00.000 UTC: 00000000008008000000000000)
reversed_max = ULID.from_uuidv4('ffffffff-ffff-4fff-bfff-ffffffffffff') #=> ULID(10889-08-02 05:31:50.655 UTC: 7ZZZZZZZZZ9ZZVZZZZZZZZZZZZ)

# But they are not reversible! Need to consider this issue in https://github.com/kachick/ruby-ulid/issues/76
ULID.min == reversed_min #=> false
ULID.max == reversed_max #=> false
```

## How to migrate from other gems

As far as I know, major prior arts are below

### [ulid gem](https://rubygems.org/gems/ulid) - [rafaelsales/ulid](https://github.com/rafaelsales/ulid)

It is just providing basic `String` generator only.
So you can replace the code as below

```diff
-ULID.generate
+ULID.generate.to_s
```

NOTE: It had crucial issue for handling precision, in version before `1.3.0`, when you extract timestamps from old generated ULIDs, it might be not accurate value.

1. [Sort order does not respect millisecond ordering](https://github.com/rafaelsales/ulid/issues/22)
1. [Fixed in this PR](https://github.com/rafaelsales/ulid/pull/23)
1. [Released in 1.3.0](https://github.com/rafaelsales/ulid/compare/1.2.0...v1.3.0)

### [ulid-ruby gem](https://rubygems.org/gems/ulid-ruby) - [abachman/ulid-ruby](https://github.com/abachman/ulid-ruby)

It is providing basic generator(except monotonic generator) and parser.
Major methods can be replaced as below.

```diff
-ULID.generate
+ULID.generate.to_s
-ULID.at(time)
+ULID.at(time).to_s
-ULID.time(string)
+ULID.parse(string).to_time
-ULID.min_ulid_at(time)
+ULID.min(time).to_s
-ULID.max_ulid_at(time)
+ULID.max(time).to_s
```

NOTE: It is still having precision issue similar as `ulid gem` in the both generator and parser. I sent PRs.

1. [Parsed time object has more than milliseconds](https://github.com/abachman/ulid-ruby/issues/3)
1. [Fix to handle timestamp precision in parser](https://github.com/abachman/ulid-ruby/pull/5)
1. [Fix to handle timestamp precision in generator](https://github.com/abachman/ulid-ruby/pull/4)

### Compare performance with them

See [Benchmark](https://github.com/kachick/ruby-ulid/wiki/Benchmark).

The results are not something to be proud of.

## References

- [Repository](https://github.com/kachick/ruby-ulid)
- [API documents](https://kachick.github.io/ruby-ulid/)
- [ulid/spec](https://github.com/ulid/spec)

## Note

- Another choices for sortable and randomness IDs, [UUIDv6, UUIDv7, UUIDv8 might be the one. (But they are still in draft state)](https://www.ietf.org/archive/id/draft-peabody-dispatch-new-uuid-format-01.html), I will track them in [ruby-ulid#37](https://github.com/kachick/ruby-ulid/issues/37)
