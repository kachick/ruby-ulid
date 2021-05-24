# frozen_string_literal: true

require 'bundler/gem_tasks'

require 'rake/testtask'

begin
  require 'rubocop/rake_task'
rescue LoadError
  puts 'can not use rubocop in this environment'
else
  RuboCop::RakeTask.new
end

task default: [:test]

# Keep lightweight!
basic_test_tasks = [:test_core, :test_experimental]
task test: basic_test_tasks

# Basically checked in CI only
task test_all: basic_test_tasks | [:test_many_data, :test_concurrency, :test_longtime]

Rake::TestTask.new(:test_core) do |tt|
  tt.pattern = 'test/core/**/test_*.rb'
  tt.verbose = true
  tt.warning = true
end

Rake::TestTask.new(:test_experimental) do |tt|
  tt.pattern = 'test/experimental/**/test_*.rb'
  tt.verbose = true
  tt.warning = true
end

Rake::TestTask.new(:test_many_data) do |tt|
  tt.pattern = 'test/many_data/**/test_*.rb'
  tt.verbose = true
  tt.warning = true
end

Rake::TestTask.new(:test_concurrency) do |tt|
  tt.pattern = 'test/concurrency/**/test_*.rb'
  tt.verbose = true
  tt.warning = true
end

Rake::TestTask.new(:test_longtime) do |tt|
  tt.pattern = 'test/longtime/**/test_*.rb'
  tt.verbose = true
  tt.warning = true
end

task validate_signatures: [:test_yard, :'signature:validate']

multitask simulate_ci: [:test_all, :validate_signatures, :rubocop]

namespace :signature do
  task :validate do
    sh 'bundle exec rbs -rsecurerandom -rmonitor -I sig validate'
  end

  task :check_false_positive do
    sh 'bundle exec steep check --log-level=fatal'
  end
end

task :test_yard do
  sh "bundle exec yard --fail-on-warning #{'--no-progress' if ENV['CI']}"
end

task :yard do
  sh 'bundle exec yard --fail-on-warning'
end

task :benchmark do
  sh 'bundle exec ruby ./benchmark/generators.rb'
  sh 'bundle exec ruby ./benchmark/core_instance_methods.rb'
  sh 'bundle exec ruby ./benchmark/extra_instance_methods.rb'
  sh 'bundle exec ruby ./benchmark/sort.rb'
  sh 'bundle exec ruby ./benchmark/sample.rb'
end

# This can't be used `bundle exec rake benchmark_with_other_gems`. Use `rake benchmark_with_other_gems` instead
task :benchmark_with_other_gems do
  puts '#### rafaelsales - ulid'
  sh 'cd ./benchmark/compare_with_othergems/rafaelsales && bundle install --quiet && bundle exec ruby -v ./generate.rb'
  puts '-' * 72
  puts '#### abachman - ulid-ruby'
  sh 'cd ./benchmark/compare_with_othergems/abachman && bundle install --quiet && bundle exec ruby -v ./generate.rb'
  puts '-' * 72
  puts '#### kachick - ruby-ulid(This one)'
  sh 'cd ./benchmark/compare_with_othergems/kachick && bundle install --quiet && bundle exec ruby -v ./generate.rb'
end

task :update_fixed_examples do
  sh 'rm ./test/many_data/fixtures/dumped_fixed_examples_*.bin'
  sh 'bundle exec ruby ./scripts/generate_many_examples.rb'
end
