# coding: us-ascii
# frozen_string_literal: true
# Copyright (C) 2021 Kenichi Kamiya

class ULID
  class MonotonicGenerator
    attr_accessor :latest_milliseconds, :latest_entropy

    def initialize
      reset
    end

    # @raise [OverflowError] if the entropy part is larger than the ULID limit in same milliseconds
    # @return [ULID]
    def generate
      milliseconds = ULID.current_milliseconds
      reasonable_entropy = ULID.reasonable_entropy

      @latest_milliseconds ||= milliseconds
      @latest_entropy ||= reasonable_entropy
      if @latest_milliseconds != milliseconds
        @latest_milliseconds = milliseconds
        @latest_entropy = reasonable_entropy
      else
        @latest_entropy += 1
      end

      ULID.new milliseconds: milliseconds, entropy: @latest_entropy
    end

    # @return [self]
    def reset
      @latest_milliseconds = nil
      @latest_entropy = nil
      self
    end

    # @raise [TypeError] always raises exception and does not freeze self
    # @return [void]
    def freeze
      raise TypeError, "cannot freeze #{self.class}"
    end
  end
end
