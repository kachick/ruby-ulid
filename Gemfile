# frozen_string_literal: true

source('https://rubygems.org')

gemspec

group(:development, :test) do
  gem('rake', '~> 13.2.1')
  gem('irb', '~> 1.14.0')
  gem('irb-power_assert', '0.3.1')
  gem('perfect_toml', '~> 0.9.0', require: false)
end

group(:development) do
  gem('debug', '~> 1.9.2', require: false)
  gem('rbs', '~> 3.5.2', require: false)
  gem('steep', '~> 1.7.1', require: false)
  gem('benchmark-ips', '~> 2.13.0', require: false)
  gem('stackprof')
  gem('yard', '~> 0.9.36', require: false)
  gem('rubocop', '~> 1.65.0', require: false)
  gem('rubocop-rake', '~> 0.6.0', require: false)
  gem('rubocop-performance', '~> 1.21.1', require: false)
  gem('rubocop-thread_safety', '~> 0.5.1', require: false)
end

group(:test) do
  gem('test-unit', '~> 3.6.2')
  gem('warning', '~> 1.4.0')
end
