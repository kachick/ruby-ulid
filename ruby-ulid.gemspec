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
    ULID(Universally Unique Lexicographically Sortable Identifier) is defined on https://github.com/ulid/spec.
    It has useful specs for actual applications.
    This gem aims to provide the generator, monotonic generator, parser and handy manipulation methods for the ID.
    Also having rbs signature files.
  EOF
  gem.homepage      = repository_url
  gem.license       = 'MIT'
  gem.name          = lib_name
  gem.version       = ULID::VERSION

  gem.metadata = {
    'documentation_uri' => "https://rubydoc.info/github/kachick/#{lib_name}/",
    'homepage_uri'      => repository_url,
    'source_code_uri'   => repository_url,
  }

  gem.add_runtime_dependency 'integer-base', '>= 0.1.1'

  gem.add_development_dependency 'test-unit', '>= 3.4.1', '< 4'
  gem.add_development_dependency 'benchmark-ips', '>= 2.8.4', '< 3'
  gem.add_development_dependency 'yard', '>= 0.9.26', '< 2'

  gem.required_ruby_version = '>= 2.5'
  
  # common

  gem.authors       = ['Kenichi Kamiya']
  gem.email         = ['kachick1+ruby@gmail.com']
  gem.files         = `git ls-files`.split($\)
  gem.require_paths = ['lib']
end
