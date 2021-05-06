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

## Policy for the adding dependencies

* Keep no runtime dependencies except `https://github.com/ruby/*` projects
* Keep clean environment in `test` group. Do not add gems like active_support into `test` group # ref: [My struggle](https://github.com/kachick/ruby-ulid/pull/42#discussion_r623960639)

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
