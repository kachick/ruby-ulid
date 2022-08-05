# How to contribute

- Reporting bugs
- Suggesting features
- Creating PRs

Welcome all of the contributions!

## Development

At first, you should install development dependencies

```console
$ git clone git@github.com:kachick/ruby-ulid.git
$ cd ./ruby-ulid
$ ./bin/setup
# Executing first time might take longtime, because development mode dependent active_support via steep
```

Author is using vscode for development. For your information, the rubocop vscode integration shows wrong errors for Rakefile and ruby-ulid.gemspec as below

```text
The name of this source file (`Rakefile'`) should use snake_case.
```

`bundle exec rubocop` does not show this messsage. It looks fixed in https://github.com/rubyide/vscode-ruby/pull/647. However it is not released yet at 2022-05-26. (https://github.com/rubyide/vscode-ruby/commit/dc81c809c82003d26af9c4dc7c89fa8f8a26cbf5 "rebornix.ruby" maintainance is inactive now)

## Touch the development version with REPL

```console
$ ./bin/console
# Starting up IRB with loading developing ULID library
irb(main):001:0> ULID::VERSION
=> "0.7.0.pre"
```

```ruby
# On IRB, you can touch behaviors even if it is undocumented
ulid = ULID.generate #=> ULID(2021-04-27 17:27:22.826 UTC: 01F4A5Y1YAQCYAYCTC7GRMJ9AA)
ls ULID

# constants:
#   ENCODED_LENGTH           Error                      MAX_ENTROPY               MAX_INTEGER
#   MAX_MILLISECONDS         MonotonicGenerator         OCTETS_LENGTH             OverflowError
#   ParserError              RANDOMNESS_ENCODED_LENGTH  RANDOMNESS_OCTETS_LENGTH  TIMESTAMP_ENCODED_LENGTH
#   TIMESTAMP_OCTETS_LENGTH  UnexpectedError            VERSION
# Module#methods: ...
# Class#methods: ...
# ULID.methods:
#   at         decode_time               encode  floor                 from_integer  generate  max   min
#   normalize  normalized?               parse   parse_variant_format  range         sample    scan  try_convert
#   valid?     valid_as_variant_format?
# => nil
```

## How to make ideal PRs (Not a mandatory rule, feel free to PR!)

If you try to add/change/fix features, please update and/or confirm core feature's tests are not broken.

```console
$ bundle exec rake test
$ echo $?
0
```

If you want to run partially tests, test-unit can take some patterns(String/Regexp) with the naming.

```console
$ bundle exec rake test TESTOPTS="-v -n'/test_.*generate/i'"
/Users/kachick/.rubies/ruby-3.0.1/bin/ruby -w -I"lib" /Users/kachick/repos/ruby-ulid/vendor/bundle/ruby/3.0.0/gems/rake-13.0.3/lib/rake/rake_test_loader.rb "test/core/test_boundary_ulid.rb" "test/core/test_frozen_ulid.rb" "test/core/test_ulid_class.rb" "test/core/test_ulid_example_values.rb" "test/core/test_ulid_instance.rb" "test/core/test_ulid_monotonic_generator.rb" "test/core/test_ulid_subclass.rb" "test/core/test_ulid_usecase.rb" -v -n'/test_.*generate/i'
Loaded suite /Users/kachick/repos/ruby-ulid/vendor/bundle/ruby/3.0.0/gems/rake-13.0.3/lib/rake/rake_test_loader
Started
TestULIDClass:
  test_generate:											.: (0.002371)
TestULIDMonotonicGenerator:
  test_generate_ignores_lower_moment_than_prev_is_given:						.: (0.002052)
  test_generate_just_bump_1_when_same_moment:								.: (0.000106)
  test_generate_optionally_take_moment_as_milliseconds:							.: (0.002259)
  test_generate_optionally_take_moment_as_time:								.: (0.002548)
  test_generate_raises_overflow_when_called_on_max_entropy:						.: (0.000216)
  test_generate_with_negative_moment:									.: (0.000134)

Finished in 0.013148 seconds.
-----------------------------------------------------------------------------------------------------------------------------
7 tests, 428 assertions, 0 failures, 0 errors, 0 pendings, 0 omissions, 0 notifications
100% passed
-----------------------------------------------------------------------------------------------------------------------------
532.40 tests/s, 32552.48 assertions/s
/Users/kachick/.rubies/ruby-3.0.1/bin/ruby -w -I"lib" /Users/kachick/repos/ruby-ulid/vendor/bundle/ruby/3.0.0/gems/rake-13.0.3/lib/rake/rake_test_loader.rb "test/experimental/test_uuid_handlers.rb" -v -n'/test_.*generate/i
```

CI includes other heavy tests, signature check, lint, if you want to check them in own machine, below command is the one.

But please don't hesitate to send PRs even if something fail in this command!

```console
$ bundle exec rake simulate_ci
$ echo $?
0
```

If you try to improve any performance issue, please add benchmarking and check the result of before and after.

```console
$ bundle exec ruby benchmark/the_added_file.rb
# Showing the results
```

## ADR - Architecture decision record

### What is `ADR`?

- [English](https://github.com/joelparkerhenderson/architecture_decision_record)
- [Japanese](https://quipper.hatenablog.com/entry/architecture_decision_records)

### Adding dependencies for this gem

- Keep no runtime dependencies
- Might be unavoidably needed latest versions of ruby standard libraries from `https://github.com/ruby/*`
- Keep clean environment in `test` group. Do not add gems like `active_support` into `test` group # ref: [My struggle](https://github.com/kachick/ruby-ulid/pull/42#discussion_r623960639)

### Adding `ULID` instance variables

- Basically should be reduced. ref: [#91](kachick/ruby-ulid#91), [#236](kachick/ruby-ulid#236)
- When having some objects, they should be frozen. ref: [#126](kachick/ruby-ulid#126)

## Tasks to drop Ruby 2.7.x

- grep `RUBY_VERSION` guards
- grep `2.7`
- Remove needless `freeze` from regex literal
- Update gemspec and `TargetRubyVersion` in .rubocop.yml
