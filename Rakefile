#!/usr/bin/env rake
require 'bundler/gem_tasks'

require 'rake/testtask'

default_tasks = [:test, :test_yard]
if Gem::Version.create(RUBY_VERSION) >= Gem::Version.create('2.6.0')
  default_tasks << :'signature:validate'
end
task default: default_tasks

Rake::TestTask.new do |tt|
  tt.pattern = 'test/**/test_*.rb'
  tt.verbose = true
  tt.warning = true
end

namespace :signature do
  task :validate do
    sh 'bundle exec rbs -rsecurerandom -rsingleton -I sig validate'
  end
end

task :test_yard do
  sh "bundle exec yard --fail-on-warning #{'--no-progress' if ENV['CI']}"
end

task :yard do
  sh 'bundle exec yard --fail-on-warning'
end

