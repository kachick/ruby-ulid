# frozen_string_literal: true

source('https://rubygems.org')

gemspec

group(:development, :test) do
  gem('rake', '~> 13.0.6')
  gem('irb', '~> 1.6.2')
  gem('irb-power_assert', '0.0.3')
end

group(:development) do
  gem('debug', '~> 1.7.1', require: false)
  gem('rbs', '~> 2.8.2', require: false)
  gem('steep', '~> 1.3.0', require: false)
  gem('benchmark-ips', '~> 2.10.0', require: false)
  gem('stackprof')
  gem('yard', '~> 0.9.28', require: false)
  gem('rubocop', '~> 1.41.1', require: false)
  gem('rubocop-rake', '~> 0.6.0', require: false)
  gem('rubocop-performance', '~> 1.15.1', require: false)
  gem('rubocop-rubycw', '~> 0.1.6', require: false)
  gem('rubocop-thread_safety', '~> 0.4.4', require: false)
  gem('rubocop-md', '~> 1.1.0', require: false)
end

group(:test) do
  gem('test-unit', '~> 3.5.7')
  gem('warning', '~> 1.3.0')
end
