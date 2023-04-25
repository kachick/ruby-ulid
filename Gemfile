# frozen_string_literal: true

source('https://rubygems.org')

gemspec

group(:development, :test) do
  gem('rake', '~> 13.0.6')
  gem('irb', '~> 1.6.4')
  gem('irb-power_assert', '0.1.1')
end

group(:development) do
  gem('debug', '~> 1.7.2', require: false)
  gem('rbs', '~> 3.0.4', require: false)
  gem('steep', '~> 1.4.0', require: false)
  gem('benchmark-ips', '~> 2.12.0', require: false)
  gem('stackprof')
  gem('yard', '~> 0.9.34', require: false)
  gem('rubocop', '~> 1.50.2', require: false)
  gem('rubocop-rake', '~> 0.6.0', require: false)
  gem('rubocop-performance', '~> 1.17.1', require: false)
  gem('rubocop-thread_safety', '~> 0.5.1', require: false)
end

group(:test) do
  gem('test-unit', '~> 3.5.7')
  gem('warning', '~> 1.3.0')
end
