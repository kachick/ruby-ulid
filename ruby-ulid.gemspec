# coding: us-ascii
# frozen_string_literal: true

lib_name = 'ruby-ulid'

require_relative './lib/ulid/version'
repository_url = "https://github.com/kachick/#{lib_name}"

Gem::Specification.new do |gem|
  gem.summary       = %q{A handy ULID library}
  gem.description   = <<-'DESCRIPTION'
    The ULID(Universally Unique Lexicographically Sortable Identifier) has useful specs for applications (e.g. `Database key`), especially possess all `uniqueness`, `randomness`, `extractable timestamps` and `sortable` features.
    This gem aims to provide the generator, monotonic generator, parser and handy manipulation features around the ULID.
    Also providing `ruby/rbs` signature files.
  DESCRIPTION
  gem.homepage      = repository_url
  gem.license       = 'MIT'
  gem.name          = lib_name
  gem.version       = ULID::VERSION

  gem.metadata = {
    'documentation_uri' => 'https://kachick.github.io/ruby-ulid/',
    'homepage_uri'      => repository_url,
    'source_code_uri'   => repository_url,
    'bug_tracker_uri'   => "#{repository_url}/issues"
  }

  gem.add_development_dependency 'test-unit', '>= 3.4.1', '< 4.0'
  gem.add_development_dependency 'irb', '>= 1.3.5', '< 2.0'
  gem.add_development_dependency 'irb-power_assert', '0.0.2'
  gem.add_development_dependency 'warning', '>= 1.2.0', '< 2.0'
  gem.add_development_dependency 'rbs', '>= 1.2.0', '< 2.0'
  gem.add_development_dependency 'rake', '>= 13.0.3', '< 20.0'
  gem.add_development_dependency 'benchmark-ips', '>= 2.9.1', '< 3'
  gem.add_development_dependency 'yard', '>= 0.9.26', '< 2'
  gem.add_development_dependency 'steep', '>= 0.44.1', '< 0.50.0'
  gem.add_development_dependency 'rubocop', '>= 1.15.0', '< 1.16.0'
  gem.add_development_dependency 'rubocop-rake', '>= 0.5.1', '< 0.6.0'
  gem.add_development_dependency 'rubocop-performance', '>= 1.11.3', '< 1.12.0'
  gem.add_development_dependency 'rubocop-rubycw', '>= 0.1.6', '< 0.2.0'
  gem.add_development_dependency 'rubocop-md', '>= 1.0.1', '< 2.0.0'

  gem.required_ruby_version = '>= 2.6.0'

  # common

  gem.authors       = ['Kenichi Kamiya']
  gem.email         = ['kachick1+ruby@gmail.com']
  git_managed_files = `git ls-files`.lines.map(&:chomp)
  might_be_parsing_by_tool_as_dependabot = git_managed_files.empty?
  base_files = Dir['README*', '*LICENSE*',  'lib/**/*', 'sig/**/*'].uniq
  files = might_be_parsing_by_tool_as_dependabot ? base_files : (base_files & git_managed_files)

  if files.grep(%r!\A(?:lib|sig)/!).size < 5
    raise "obvious mistaken in packaging files, looks shortage: #{files.inspect}"
  end

  gem.files         = files
  gem.require_paths = ['lib']
end
