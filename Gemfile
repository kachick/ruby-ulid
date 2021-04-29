source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'rake', '>= 13.0.3', '< 20'

  if Gem::Version.create(RUBY_VERSION) >= Gem::Version.create('2.6.0')
    gem 'rbs', '>= 1.2.0'
  end
end

group :development do
  gem 'irb', '>= 1.3.5'
end

group :test do
  gem 'test-unit', '>= 3.4.1', '< 4'
  gem 'warning', '>= 1.2.0'
end
