# frozen_string_literal: true

source('https://rubygems.org')

gemspec

group(:development, :test) do
  gem('rake', '~> 13.2.1')
  gem('irb', '~> 1.14.2')
  gem('irb-power_assert', '0.3.1')
  gem('perfect_toml', '~> 0.9.0', require: false)
end

group(:development) do
  gem('debug', '~> 1.9.2', require: false)
  gem('rbs', '~> 3.6.1', require: false)
  gem('steep', '~> 1.8.3', require: false)
  gem('benchmark-ips', '~> 2.14.0', require: false)
  gem('stackprof')
  gem('yard', '~> 0.9.37', require: false)
  gem('rubocop', '~> 1.69.1', require: false)
  gem('rubocop-rake', '~> 0.6.0', require: false)
  gem('rubocop-performance', '~> 1.23.0', require: false)
  gem('rubocop-thread_safety', '~> 0.6.0', require: false)
end

group(:test) do
  gem('test-unit', '~> 3.6.4')
  gem('warning', '~> 1.4.0')
end
