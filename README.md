# ruby-ulid

A handy `ULID` library

The `ULID` spec is defined on [ulid/spec](https://github.com/ulid/spec).
Formal name is `Universally Unique Lexicographically Sortable Identifier`.
It has useful specs for actual applications.
This gem aims to provide the generator, monotonic generator, parser and handy manipulation methods for the ID.
Also having rbs signature files.

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

You can parse from exists IDs

```ruby
ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') #=> ULID(2016-07-30 23:54:10.259 UTC: 01ARZ3NDEKTSV4RRFFQ69G5FAV)
```

ULID is sortable when they are generated different timestamp in milliseconds precision

```ruby
ulids = 1000.times.map do
  sleep(0.001)
  ULID.generate
end
ulids.sort == ulids #=> true
ulids.uniq(&:to_time).size #=> 1000
```

Providing monotonic generator for same milliseconds use-cases. It is called as [Monotonicity](https://github.com/ulid/spec/tree/d0c7170df4517939e70129b4d6462cc162f2d5bf#monotonicity) on the spec.

```ruby
ulids = 10000.times.map do
  ULID.generate
end
ulids.uniq(&:to_time).size #=> 35 (the number will be changed by every creation)
ulids.sort == ulids #=> false


monotonic_generator = ULID::MonotonicGenerator.new
monotonic_ulids = 10000.times.map do
  monotonic_generator.generate
end
monotonic_ulids.uniq(&:to_time).size #=> 34 (the number will be changed by every creation)
monotonic_ulids.sort == monotonic_ulids #=> true
```

Providing converter for UUIDv4. (Of course the timestamp will be useless one.)

```ruby
ULID.from_uuidv4('0983d0a2-ff15-4d83-8f37-7dd945b5aa39')
#=> ULID(2301-07-10 00:28:28.821 UTC: 09GF8A5ZRN9P1RYDVXV52VBAHS)
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

## Development

At first, you should install development dependencies

```console
$ git clone git@github.com:kachick/ruby-ulid.git
$ cd ./ruby-ulid
$ bundle install
# Executing first time might take longtime, because development mode dependent active_support via steep
```

Play with the behaviors in REPL.

```console
$ ./bin/console
# Starting up IRB with loading developing ULID library
irb(main):001:0>
```

```ruby
# On IRB, you can check behaviors even if it is undocumented
ulid = ULID.generate #=> ULID(2021-04-27 17:27:22.826 UTC: 01F4A5Y1YAQCYAYCTC7GRMJ9AA)
ls ULID
```

If you try to add/change/fix features, please update tests and ensure they are not broken.

```console
$ bundle exec rake test
$ echo $?
0
```

If you try to improve any performance issue, please add benchmarking and check the result of before and after.

```console
$ bundle exec ruby benchmark/the_added_file.rb
# Showing the results
```

## Documents

- [API documents generated by YARD](https://kachick.github.io/ruby-ulid/)

## Author

Kenichi Kamiya - [@kachick](https://github.com/kachick)
