# coding: utf-8
# frozen_string_literal: true

# @todo - Replace to `Data` class since dropped Ruby 3.1 - ref: https://bugs.ruby-lang.org/issues/16122
Example = Struct.new(:string, :integer, :timestamp, :randomness, :period, :to_time, :inspect, :uuidv4, :octets, keyword_init: true)
