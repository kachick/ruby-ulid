# coding: utf-8
# frozen_string_literal: true

require('benchmark/ips')
require('ulid')

raise("Bug to setup: #{ULID.methods(false)}") unless ULID.const_defined?(:Generator)

p("`ulid gem - #{ULID::VERSION}` does not have parsers yet")
