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

basic_test_tasks = [:test_core, :test_experimental]
desc 'Keep light weight!'
task test: basic_test_tasks

desc 'Contains heavy tests. So basically checked in CI only'
task test_all: basic_test_tasks | [:test_many_data, :test_concurrency, :test_longtime]

Rake::TestTask.new(:test_core) do |tt|
  tt.pattern = 'test/core/**/test_*.rb'
  tt.warning = true
end

Rake::TestTask.new(:test_experimental) do |tt|
  tt.pattern = 'test/experimental/**/test_*.rb'
  tt.warning = true
end

Rake::TestTask.new(:test_many_data) do |tt|
  tt.pattern = 'test/many_data/**/test_*.rb'
  tt.warning = true
end

Rake::TestTask.new(:test_concurrency) do |tt|
  tt.pattern = 'test/concurrency/**/test_*.rb'
  tt.warning = true
end

Rake::TestTask.new(:test_longtime) do |tt|
  tt.pattern = 'test/longtime/**/test_*.rb'
  tt.warning = true
end

desc 'Signature check, it means `rbs` and `YARD` syntax correctness'
multitask validate_signatures: [:'signature:validate_yard', :'signature:validate_rbs']

desc 'Simulate CI results in local machine as possible'
multitask simulate_ci: [:test_all, :validate_signatures, :rubocop]

namespace :signature do
  desc 'Validate `rbs` syntax, this should be passed'
  task :validate_rbs do
    sh 'bundle exec rbs -rsecurerandom -rmonitor -I sig validate'
  end

  desc 'Check `rbs` definition with `steep`, but it faults from some reasons ref: #26'
  task :check_false_positive do
    sh 'bundle exec steep check --log-level=fatal'
  end

  desc 'Generate YARD docs for the syntax check'
  task :validate_yard do
    sh "bundle exec yard --fail-on-warning #{'--no-progress' if ENV['CI']}"
  end
end

desc 'Generate YARD docs'
task :yard do
  sh 'bundle exec yard --fail-on-warning'
end

FileList['benchmark/*.rb'].each do |path|
  desc "Rough benchmark for #{File.basename(path)}"
  task path do
    ruby path
  end
end

# This can't be used `bundle exec rake`. Use `rake` instead
desc %q{Compare generating String performance with other gems}
task :benchmark_with_other_gems do
  [{ rafaelsales: 'ulid'}, {abachman: 'ulid-ruby'}, {kachick: 'ruby-ulid(This one)'}].each do |gem_name_by_author|
    gem_name_by_author.each_pair do |author, gem_name|
      puts '-' * 72
      puts "#### #{author} - #{gem_name}"
      cd "./benchmark/compare_with_othergems/#{author}" do
        sh 'bundle install --quiet'
        sh 'bundle exec ruby -v ./generate.rb'
      end
    end
  end
end

desc 'Generate many sample data for snapshot tests'
task :update_fixed_examples do
  sh 'rm ./test/many_data/fixtures/dumped_fixed_examples_*.bin'
  ruby './scripts/generate_many_examples.rb'
end
