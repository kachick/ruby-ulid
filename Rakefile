#!/usr/bin/env rake
require 'bundler/gem_tasks'

require 'rake/testtask'

task default: [:test]
task test_all: [:test, :test_uuid, :test_heavy]

Rake::TestTask.new(:test) do |tt|
  tt.test_files = FileList['test/**/test_*.rb'].exclude(/many_data|uuid/)
  tt.verbose = true
  tt.warning = true
end

Rake::TestTask.new(:test_uuid) do |tt|
  tt.pattern = 'test/**/test_uuid*.rb'
  tt.verbose = true
  tt.warning = true
end

Rake::TestTask.new(:test_heavy) do |tt|
  tt.pattern = 'test/many_data/**/test_*.rb'
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
end

task :update_fixed_examples do
  filepath = './test/many_data/fixtures/dumped_fixed_examples.dat'
  sh "rm #{filepath}" do |ok, status|
    p({ok: ok, status: status})
  end
  sh "bundle exec ruby scripts/generate_many_examples.rb > #{filepath}"
end
