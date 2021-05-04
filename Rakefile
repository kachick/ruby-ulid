#!/usr/bin/env rake
require 'bundler/gem_tasks'

require 'rake/testtask'

task default: [:test]

Rake::TestTask.new do |tt|
  tt.pattern = 'test/**/test_*.rb'
  tt.verbose = true
  tt.warning = true
end

task sub_test: [:test_yard, :'signature:validate']

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
  sh 'bundle exec ruby benchmark/sort.rb'
end
