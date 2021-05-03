# ruby-ulid

![Build Status](https://github.com/kachick/ruby-ulid/actions/workflows/test.yml/badge.svg?branch=main)
[![Gem Version](https://badge.fury.io/rb/ruby-ulid.png)](http://badge.fury.io/rb/ruby-ulid)

A handy `ULID` library

The `ULID` spec is defined on https://github.com/ulid/spec.
Formal name is `Universally Unique Lexicographically Sortable Identifier`.

## Install

```console
$ gem install ruby-ulid
```

## Uninstall

```console
$ gem uninstall ruby-ulid
```

## Usage

The generated `ULID` is an object rather than just a string.
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
$ bundle install
```

Easy to play with the behaviors in REPL.

```console
$ bin/console
```

If you try to add features, please ensure exist test cases are not broken

```console
$ bundle exec rake test
```

If you try to improve any performance issue, please check the result of benchmarking before and after.

```console
$ bundle exec ruby benchmark/*
```

## Link

* [API documentation](https://rubydoc.info/github/kachick/ruby-ulid/)

## Author

Kenichi Kamiya - [@kachick](https://github.com/kachick)
