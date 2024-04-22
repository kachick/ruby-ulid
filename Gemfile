# frozen_string_literal: true

source('https://rubygems.org')

gemspec

group(:development, :test) do
  gem('rake', '~> 13.2.1')
  gem('irb', '~> 1.12.0')
  gem('irb-power_assert', '0.2.0')
  gem('perfect_toml', '~> 0.9.0', require: false)
end

group(:development) do
  gem('debug', '~> 1.9.2', require: false)
  gem('rbs', '~> 3.4.4', require: false)
  gem('steep', '~> 1.6.0', require: false)
  gem('benchmark-ips', '~> 2.13.0', require: false)
  gem('stackprof')
  gem('yard', '~> 0.9.36', require: false)
  gem('rubocop', '~> 1.63.2', require: false)
  gem('rubocop-rake', '~> 0.6.0', require: false)
  gem('rubocop-performance', '~> 1.21.0', require: false)
  gem('rubocop-thread_safety', '~> 0.5.1', require: false)
end

group(:test) do
  gem('test-unit', '~> 3.6.2')
  gem('warning', '~> 1.3.0')
end
