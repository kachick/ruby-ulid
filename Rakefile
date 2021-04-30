#!/usr/bin/env rake
require 'bundler/gem_tasks'

require 'rake/testtask'

task default: [:test]

Rake::TestTask.new do |tt|
  tt.pattern = 'test/**/test_*.rb'
  tt.verbose = true
  tt.warning = true
end

sub_tests = [:test_yard]
if Gem::Version.create(RUBY_VERSION) >= Gem::Version.create('2.6.0')
  sub_tests << :'signature:validate'
end
task sub_test: sub_tests

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
  sh 'bundle exec ruby benchmark/generate.rb'
  sh 'bundle exec ruby benchmark/to_s.rb'
end