# coding: utf-8
# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/ulid'

Benchmark.ips do |x|
  x.report('ULID#to_s / This is depending to #to_i') { ULID.sample.to_s }
  x.report('ULID#to_i') { ULID.sample.to_i }
  x.report('ULID#to_time') { ULID.sample.to_time }
  x.report('ULID#milliseconds / Should be fast, because nothing any calculations for now') { ULID.sample.milliseconds }

  x.compare!
end
