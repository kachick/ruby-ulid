# frozen_string_literal: true

require('bundler/gem_tasks')

require('rake/testtask')

begin
  require('rubocop/rake_task')
rescue LoadError
  puts('can not use rubocop in this environment')
else
  RuboCop::RakeTask.new
end

multitask(default: %i[test signature_all rubocop validate_gem dprint])

desc('Keep light weight!')
task(test: :test_core)

desc('Contains heavy tests. So basically checked in CI only')
task(test_all: %i[test_core test_many_data test_concurrency test_longtime])

Rake::TestTask.new(:test_core) do |tt|
  tt.pattern = 'test/core/**/test_*.rb'
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

desc('Signature check, it means `rbs` and `YARD` syntax correctness')
multitask(rbs: %i[signature:validate_rbs signature:check_rbs_false_positive])
multitask(signature_all: %i[signature:validate_yard rbs])

desc('Simulate CI results in local machine as possible')
multitask(simulate_ci: %i[test_all signature_all rubocop dprint])

namespace(:signature) do
  desc('Validate `rbs` syntax, this should be passed')
  task(:validate_rbs) do
    sh('bundle exec rbs -rsecurerandom -rmonitor -I sig validate')
  end

  desc('Check `rbs` definition with `steep` and save alerts into ignoring list :<')
  task(:save_rbs_errors) do
    sh('bundle exec steep check --severity-level=warning --log-level=fatal --save-expectations')
  end

  desc('Check `rbs` definition with `steep`, should be passed at least considering steep_expectations.yml')
  task(:check_rbs_false_positive) do
    sh('bundle exec steep check --severity-level=warning --log-level=fatal --with-expectations')
  end

  desc('Run YARD without docs generating for the syntax check')
  task(:validate_yard) do
    sh('bundle exec yard stats')
  end
end

task(:list_todo) do
  sh("bundle exec yard list --query '@todo'")
  sh('git', 'grep', '-Pni', 'FIX ?ME', '**/*.rb', '**/*.gemspec', '**/Gemfile')
end

FileList['benchmark/*.rb'].each do |path|
  desc("Rough benchmark for #{File.basename(path)}")
  task(path) do
    ruby(path)
  end
end

# This can't be used `bundle exec rake`. Use `rake` instead
desc(%q{Compare generating String performance with other gems})
task(:benchmark_with_other_gems) do
  [{ kachick: 'ruby-ulid(This one)' }, { rafaelsales: 'ulid' }, { abachman: 'ulid-ruby' }].each do |gem_name_by_author|
    gem_name_by_author.each_pair do |author, gem_name|
      puts('-' * 72)
      puts("#### #{author} - #{gem_name}")
      cd("./benchmark/compare_with_othergems/#{author}") do
        sh('bundle install --quiet')
        sh('bundle exec ruby -v ./generate.rb')
        sh('bundle exec ruby -v ./parser.rb')
      end
    end
  end
end

task(:stackprof) do
  # Cannot use remove_entry_secure for using glob
  sh('rm -rf ./tmp/stackprof-*')
  sh('bundle exec ruby ./scripts/prof.rb')
  sh('bundle exec stackprof tmp/stackprof-wall-*.dump --text --limit 5')
  sh('bundle exec stackprof tmp/stackprof-cpu-*.dump --text --limit 5')
end

desc('Generate samples for snapshot tests')
task(:generate_snapshots) do
  ruby('./scripts/generate_snapshots.rb')
end

task(:validate_gem) do
  sh('gem build --strict --norc --backtrace ruby-ulid.gemspec')
end

desc('To prevent #69 anymore!')
task(:view_packaging_files) do
  remove_entry_secure('./pkg')
  sh('rake build')
  cd('pkg') do
    sh('gem unpack *.gem')
    sh('tree -I *\.gem')
  end
  remove_entry_secure('./pkg')
end

task(:dprint) do
  sh('dprint check')
end

task(:update) do
  sh('dprint config update')
end

desc 'Print dependencies'
task :deps do
  sh('ruby --version')
  sh('dprint --version')
  sh('tree --version')
  sh('typos --version')
end

desc 'Tests except ruby'
task :check_non_ruby do
  Rake::Task['dprint'].invoke
  sh('typos . .github .vscode')
  # nix fmt doesn't have check: https://github.com/NixOS/nix/issues/6918
  sh("git ls-files '*.nix' | xargs nixfmt --check")
end

task :tag do
  sh(%q!ruby -r './lib/ulid/version' -e 'puts "v#{ULID::VERSION}"' | xargs --no-run-if-empty --max-lines=1 git tag!) # rubocop:disable Lint/InterpolationCheck
end
