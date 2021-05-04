# coding: us-ascii
# frozen_string_literal: true

lib_name = 'ruby-ulid'

require './lib/ulid/version'
repository_url = "https://github.com/kachick/#{lib_name}"

Gem::Specification.new do |gem|
  gem.authors       = ['Kenichi Kamiya']
  gem.email         = ['kachick1+ruby@gmail.com']
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

  gem.add_runtime_dependency 'integer-base', '>= 0.1.2', '< 0.2.0'

  gem.add_development_dependency 'rbs', '>= 1.2.0'
  gem.add_development_dependency 'benchmark-ips', '>= 2.8.4', '< 3'
  gem.add_development_dependency 'yard', '>= 0.9.26', '< 2'

  gem.required_ruby_version = '>= 2.6.0'
  
  # common

  gem.authors       = ['Kenichi Kamiya']
  gem.email         = ['kachick1+ruby@gmail.com']
  git_ls_filepaths = `git ls-files`.lines.map(&:chomp)
  minimum_filepaths = git_ls_filepaths.grep(%r!\A(?:lib|sig)/!)
  raise "obvious mistaken in packaging files: #{minimum_filepaths.inspect}" if minimum_filepaths.size < 2
  extra_filepaths = %w[README.md LICENSE]
  raise 'git ignores extra filename' unless (extra_filepaths - git_ls_filepaths).empty?
  gem.files         = minimum_filepaths | extra_filepaths
  gem.require_paths = ['lib']
end
