source 'https://rubygems.org'

gemspec

is_rbs_supported = Gem::Version.create(RUBY_VERSION) >= Gem::Version.create('2.6.0')

group :development, :test do
  gem 'rake', '>= 13.0.3', '< 20'

  if is_rbs_supported
    gem 'rbs', '>= 1.2.0'
  end
end

group :development do
  gem 'irb', '>= 1.3.5'

  if is_rbs_supported
    gem 'steep', '>= 0.44.1'
  end
end

group :test do
  gem 'test-unit', '>= 3.4.1', '< 4'
  gem 'warning', '>= 1.2.0'
end
