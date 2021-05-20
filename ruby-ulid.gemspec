# coding: us-ascii
# frozen_string_literal: true

lib_name = 'ruby-ulid'

require_relative './lib/ulid/version'
repository_url = "https://github.com/kachick/#{lib_name}"

Gem::Specification.new do |gem|
  gem.summary       = %q{A handy ULID library}
  gem.description   = <<-EOF
    The ULID(Universally Unique Lexicographically Sortable Identifier) has useful specs for applications (e.g. `Database key`), especially possess all `uniqueness`, `randomness`, `extractable timestamps` and `sortable` features.
    This gem aims to provide the generator, monotonic generator, parser and handy manipulation features around the ULID.
    Also providing `ruby/rbs` signature files.
  EOF
  gem.homepage      = repository_url
  gem.license       = 'MIT'
  gem.name          = lib_name
  gem.version       = ULID::VERSION

  gem.metadata = {
    'documentation_uri' => 'https://kachick.github.io/ruby-ulid/',
    'homepage_uri'      => repository_url,
    'source_code_uri'   => repository_url,
  }

  gem.add_development_dependency 'test-unit', '>= 3.4.1', '< 4.0'
  gem.add_development_dependency 'irb', '>= 1.3.5', '< 2.0'
  gem.add_development_dependency 'irb-power_assert', '0.0.2'
  gem.add_development_dependency 'warning', '>= 1.2.0', '< 2.0'
  gem.add_development_dependency 'rbs', '>= 1.2.0', '< 2.0'
  gem.add_development_dependency 'rake', '>= 13.0.3', '< 20.0'
  gem.add_development_dependency 'benchmark-ips', '>= 2.8.4', '< 3'
  gem.add_development_dependency 'yard', '>= 0.9.26', '< 2'
  gem.add_development_dependency 'steep', '>= 0.44.1', '< 0.50.0'
  gem.add_development_dependency 'rubocop', '>= 1.14.0', '< 1.15.0'
  gem.add_development_dependency 'rubocop-rake'
  gem.add_development_dependency 'rubocop-performance'
  gem.add_development_dependency 'rubocop-rubycw'
  gem.add_development_dependency 'rubocop-md'

  gem.required_ruby_version = '>= 2.6.0'

  # common

  gem.authors       = ['Kenichi Kamiya']
  gem.email         = ['kachick1+ruby@gmail.com']
  files = Dir['README*', '*LICENSE*',  'lib/**/*', 'sig/**/*'].uniq
  raise "obvious mistaken in packaging files: #{files.inspect}" unless files.grep(%r!\A(?:lib|sig)/!).size > 5
  gem.files         = files
  gem.require_paths = ['lib']
end
