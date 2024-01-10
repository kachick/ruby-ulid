# coding: us-ascii
# frozen_string_literal: true

lib_name = 'ruby-ulid'

require_relative('lib/ulid/version')
repository_url = "https://github.com/kachick/#{lib_name}"

Gem::Specification.new do |gem|
  gem.summary       = %q{ULID manipulation library}
  gem.description   = <<-'DESCRIPTION'
    generator, optional monotonicity, parser and tools for ULID (RBS included)
  DESCRIPTION
  gem.homepage      = repository_url
  gem.license       = 'MIT'
  gem.name          = lib_name
  gem.version       = ULID::VERSION

  gem.metadata = {
    'documentation_uri' => 'https://kachick.github.io/ruby-ulid/',
    'homepage_uri' => repository_url,
    'source_code_uri' => repository_url,
    'bug_tracker_uri' => "#{repository_url}/issues",
    'rubygems_mfa_required' => 'true'
  }

  gem.required_ruby_version = Gem::Requirement.new('>= 3.2')

  # common

  gem.authors       = ['Kenichi Kamiya']
  gem.email         = ['kachick1+ruby@gmail.com']
  git_managed_files = `git ls-files`.lines.map(&:chomp)
  might_be_parsing_by_tool_as_dependabot = git_managed_files.empty?
  base_files = Dir['README*', '*LICENSE*', 'lib/**/*', 'sig/**/*'].uniq
  files = might_be_parsing_by_tool_as_dependabot ? base_files : (base_files & git_managed_files)

  unless might_be_parsing_by_tool_as_dependabot
    if files.grep(%r!\A(?:lib|sig)/!).size < 5
      raise("obvious mistaken in packaging files, looks shortage: #{files.inspect}")
    end
  end

  gem.files         = files
  gem.require_paths = ['lib']
end
