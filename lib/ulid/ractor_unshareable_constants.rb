# coding: us-ascii
# frozen_string_literal: true

class ULID
  min = parse('00000000000000000000000000').freeze
  max = parse('7ZZZZZZZZZZZZZZZZZZZZZZZZZ').freeze

  ractor_can_make_shareable_time = RUBY_VERSION >= '3.1'

  MIN = ractor_can_make_shareable_time ? Ractor.make_shareable(min) : min
  MAX = ractor_can_make_shareable_time ? Ractor.make_shareable(max) : max

  private_constant(:MIN, :MAX)
end
