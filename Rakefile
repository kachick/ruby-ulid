#!/usr/bin/env rake
require 'bundler/gem_tasks'

require 'rake/testtask'

task default: [:test]

# Keep lightweight!
basic_test_tasks = [:test_core, :test_experimental]
task test: basic_test_tasks

# Basically checked in CI only
task test_all: basic_test_tasks | [:test_many_data, :test_concurrency]

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

task test_signatures: [:test_yard, :'signature:validate']

namespace :signature do
  task :validate do
    sh 'bundle exec rbs -rsecurerandom -I sig validate'
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
  sh 'bundle exec ruby benchmark/generators.rb'
  sh 'bundle exec ruby benchmark/core_instance_methods.rb'
  sh 'bundle exec ruby benchmark/extra_instance_methods.rb'
  sh 'bundle exec ruby benchmark/sort.rb'
  sh 'bundle exec ruby benchmark/sample.rb'
end

task :update_fixed_examples do
  filepath = './test/many_data/fixtures/dumped_fixed_examples.dat'
  sh "rm #{filepath}" do |ok, status|
    p({ok: ok, status: status})
  end
  sh "bundle exec ruby scripts/generate_many_examples.rb > #{filepath}"
end
