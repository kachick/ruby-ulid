<h1 align="center">
	<br>
	<br>
	<img width="360" src="logo.png" alt="ulid">
	<br>
	<br>
	<br>
</h1>

![Build Status](https://github.com/kachick/ruby-ulid/actions/workflows/test.yml/badge.svg?branch=main)
[![Gem Version](https://badge.fury.io/rb/ruby-ulid.png)](http://badge.fury.io/rb/ruby-ulid)
# ruby-ulid

A handy `ULID` library

The `ULID` spec is defined on [ulid/spec](https://github.com/ulid/spec).
Formal name is `Universally Unique Lexicographically Sortable Identifier`.

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
```

You can parse from exists IDs

```ruby
ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') #=> ULID(2016-07-30 23:54:10.259 UTC: 01ARZ3NDEKTSV4RRFFQ69G5FAV)
```

Providing monotonic generator. It is called as [Monotonicity](https://github.com/ulid/spec/tree/d0c7170df4517939e70129b4d6462cc162f2d5bf#monotonicity) on the spec.

```ruby
ulids = 10000.times.map do
  ULID.generate
end
ulids.sort == ulids #=> false

monotonic_ulids = 10000.times.map do
  ULID.monotonic_generate
end
monotonic_ulids.sort == monotonic_ulids #=> true
```

## Development

At first, you should install development dependencies

```console
$ git clone git@github.com:kachick/ruby-ulid.git
$ cd ./ruby-ulid
$ bundle install
```

Play with the behaviors in REPL.

```console
$ ./bin/console
ulid = ULID.generate #=> ULID(2021-04-27 17:27:22.826 UTC: 01F4A5Y1YAQCYAYCTC7GRMJ9AA)
```

If you try to add/change/fix features, please update tests and ensure they are not broken.

```console
$ bundle exec rake test
```

If you try to improve any performance issue, please add benchmarking and check the result of before and after.

```console
$ bundle exec ruby benchmark/*
```

## API Documentation

[Hosted on rubydoc](https://rubydoc.info/github/kachick/ruby-ulid/), but it is not synched to latest one.
Recommend to generate from source for now.

```console
$ bundle exec yard
Files:           2
Modules:         0 (    0 undocumented)
Classes:         4 (    3 undocumented)
Constants:      10 (   10 undocumented)
Attributes:      4 (    0 undocumented)
Methods:        23 (    0 undocumented)
 68.29% documented
$ open ./doc/index.html
```

## Author

Kenichi Kamiya - [@kachick](https://github.com/kachick)
