# How to contribute

- Reporting bugs
- Suggesting features
- Creating PRs

Welcome all of the contributions!

## Setup

Needs your ruby and [dprint](https://dprint.dev/) for development.\
If you are using [Nix](https://nixos.org/) package manager, [the definition](shell.nix) is included.

```console
$ git clone git@github.com:kachick/ruby-ulid.git
$ cd ./ruby-ulid
$ nix-shell
$ dprint --version
$ bundle install || bundle update
```

## Dprint

Use dprint as below

```console
$ dprint --config dprint-ci.json check
$ dprint --config dprint-ci.json fmt
```

Providing 2 config files. For the purpose below

- [dprint-ci.json](dprint-ci.json) - Except ruby for faster run
- [dprint.json](dprint.json) - Includes rubocop integration. Just using in vscode

## Rubocop

Using rubocop as a formatter. So recommend to execute it with servermode before editting code to reduce time.

```console
$ bundle exec rubocop --start-server
```

Vscode tasks does not include it because of executed server process will exists even after closing vscode.\
Please manually kill it as below.

```console
$ bundle exec rubocop --stop-server
```

See [microsoft/vscode#65986](https://github.com/microsoft/vscode/issues/65986) for further detail.

## Touch the development version with REPL

```console
$ ./bin/console
# Starting up IRB with loading developing ULID library
irb(main):001:0> ULID::VERSION
=> "0.8.0.pre"
```

```ruby
# On IRB, you can touch behaviors even if it is undocumented
ulid = ULID.generate #=> ULID(2021-04-27 17:27:22.826 UTC: 01F4A5Y1YAQCYAYCTC7GRMJ9AA)
ls ULID

# constants:
#   ..., Error, ...VERSION, ...
# Module#methods: ...
# Class#methods: ...
# ULID.methods:
#   at                        decode_time  encode  floor                 from_integer  generate  max   min
#   normalize                 normalized?  parse   parse_variant_format  range         sample    scan  try_convert
#   valid_as_variant_format?
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
❯ bundle exec rake test TESTOPTS="-v -n'/test_.*generate/i'"
Loaded suite /nix/store/d2grc9vz9d3bgl3ncjj7s0nrqi4xz003-ruby-3.2.1/lib/ruby/gems/3.2.0/gems/rake-13.0.6/lib/rake/rake_test_loader
Started
TestULIDClass:
  test_generate:                                                                                        .: (0.000568)
  test_generate_with_invalid_arguments:                                                                 .: (0.001486)
TestULIDMonotonicGenerator:
  test_generate_and_encode_can_be_used_together:                                                        .: (0.001844)
  test_generate_ignores_lower_moment_than_last_is_given:                                                .: (0.000249)
  test_generate_just_bump_1_when_same_moment:                                                           .: (0.000173)
  test_generate_optionally_take_moment_as_milliseconds:                                                 .: (0.001897)
  test_generate_optionally_take_moment_as_time:                                                         .: (0.004004)
  test_generate_raises_overflow_when_called_on_max_entropy:                                             .: (0.000288)
  test_generate_with_negative_moment:                                                                   .: (0.000098)

Finished in 0.011706387 seconds.
------------------------------------------------------------------------------------------------------------------------
9 tests, 503 assertions, 0 failures, 0 errors, 0 pendings, 0 omissions, 0 notifications
100% passed
------------------------------------------------------------------------------------------------------------------------
768.81 tests/s, 42968.00 assertions/s
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

## Tasks to drop Ruby 3.1

- grep `RUBY_VERSION` guards
- grep `3.1` and '3.2'
- Update gemspec and `TargetRubyVersion` in .rubocop.yml
