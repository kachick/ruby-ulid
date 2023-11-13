# frozen_string_literal: true

source('https://rubygems.org')

gemspec

group(:development, :test) do
  gem('rake', '~> 13.1.0')
  gem('irb', '~> 1.9.0')
  gem('irb-power_assert', '0.2.0')
end

group(:development) do
  gem('debug', '~> 1.8.0', require: false)
  gem('rbs', '~> 3.3.0', require: false)
  gem('steep', '~> 1.6.0', require: false)
  gem('benchmark-ips', '~> 2.12.0', require: false)
  gem('stackprof')
  gem('yard', '~> 0.9.34', require: false)
  gem('rubocop', '~> 1.57.2', require: false)
  gem('rubocop-rake', '~> 0.6.0', require: false)
  gem('rubocop-performance', '~> 1.19.1', require: false)
  gem('rubocop-thread_safety', '~> 0.5.1', require: false)
end

group(:test) do
  gem('test-unit', '~> 3.6.1')
  gem('warning', '~> 1.3.0')
end
