# coding: us-ascii
# frozen_string_literal: true
# Copyright (C) 2021 Kenichi Kamiya

class ULID
  class MonotonicGenerator
    # @api private
    attr_accessor :latest_milliseconds, :latest_entropy

    def initialize
      @mutex = Thread::Mutex.new
      reset
    end

    # @param [Time, Integer] moment
    # @return [ULID]
    # @raise [OverflowError] if the entropy part is larger than the ULID limit in same milliseconds
    # @raise [ArgumentError] if the given moment(milliseconds) is negative number
    def generate(moment: ULID.current_milliseconds)
      milliseconds = ULID.milliseconds_from_moment(moment)
      raise ArgumentError, "milliseconds should not be negative: given: #{milliseconds}" if milliseconds.negative?

      @mutex.synchronize do
        if @latest_milliseconds < milliseconds
          @latest_milliseconds = milliseconds
          @latest_entropy = ULID.reasonable_entropy
        else
          @latest_entropy += 1
        end
        ULID.from_milliseconds_and_entropy(milliseconds: @latest_milliseconds, entropy: @latest_entropy)
      end
    end

    # @api private
    # @return [void]
    def reset
      @latest_milliseconds = 0
      @latest_entropy = ULID.reasonable_entropy
      nil
    end

    # @raise [TypeError] always raises exception and does not freeze self
    # @return [void]
    def freeze
      raise TypeError, "cannot freeze #{self.class}"
    end
  end
end
