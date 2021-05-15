# How to contribute

* Reporting bugs
* Suggesting features
* Creating PRs

Welcome all of the contributions!

## Development

At first, you should install development dependencies

```console
$ git clone git@github.com:kachick/ruby-ulid.git
$ cd ./ruby-ulid
$ bundle install
# Executing first time might take longtime, because development mode dependent active_support via steep
```

## Ensuring pre-release version's behaviors

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

## How to make ideal PRs (Not a mandatory rule, feel free to PR!)

If you try to add/change/fix features, please update and/or confirm core feature's tests are not broken.

```console
$ bundle exec rake test
$ echo $?
0
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

* [English](https://github.com/joelparkerhenderson/architecture_decision_record)
* [Japanese](https://quipper.hatenablog.com/entry/architecture_decision_records)

### Adding dependencies for this gem

* Keep no runtime dependencies except `https://github.com/ruby/*` projects
* Keep clean environment in `test` group. Do not add gems like `active_support` into `test` group # ref: [My struggle](https://github.com/kachick/ruby-ulid/pull/42#discussion_r623960639)

### Adding `ULID` instance variables

* Basically should be reduced. ref: [#91](https://github.com/kachick/ruby-ulid/issues/91)
* When having some objects, they should be frozen. ref: [#126](https://github.com/kachick/ruby-ulid/pull/126)
* Reader methods should return same value, should not be changed
