# frozen_string_literal: true

source('https://rubygems.org')

gemspec

group(:development, :test) do
  gem('rake', '~> 13.2.1')
  gem('irb', '~> 1.15.1')
  gem('irb-power_assert', '0.4.0')
  gem('perfect_toml', '~> 0.9.0', require: false)
end

group(:development) do
  gem('debug', '~> 1.10.0', require: false)
  gem('rbs', '~> 3.6.1', require: false)
  gem('steep', '~> 1.8.3', require: false)
  gem('benchmark-ips', '~> 2.14.0', require: false)
  gem('stackprof')
  gem('yard', '~> 0.9.37', require: false)
  gem('rubocop', '~> 1.74.0', require: false)
  gem('rubocop-rake', '~> 0.7.1', require: false)
  gem('rubocop-performance', '~> 1.24.0', require: false)
  gem('rubocop-thread_safety', '~> 0.7.2', require: false)
end

group(:test) do
  gem('test-unit', '~> 3.6.7')
  gem('warning', '~> 1.5.0')
end
