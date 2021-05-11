# coding: us-ascii
# frozen_string_literal: true
# Copyright (C) 2021 Kenichi Kamiya

class ULID
  class MonotonicGenerator
    class ConcurrencyError < ThreadError; end

    # @api private
    attr_accessor :latest_milliseconds, :latest_entropy

    # @return [ULID, nil]
    attr_reader :last

    undef_method :instance_variable_set

    def initialize
      @mutex = Thread::Mutex.new
      reset
    end

    # @return [String]
    def inspect
      "ULID::MonotonicGenerator(last: #{@last.inspect})"
    end
    alias_method :to_s, :inspect

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
        ulid = ULID.from_milliseconds_and_entropy(milliseconds: @latest_milliseconds, entropy: @latest_entropy)
        if @last && !(ulid > @last)
          raise ConcurrencyError,
            "This error means generated obviously unsuitable ULID. this_time:#{ulid.inspect} - last_time:#{@last.inspect}, we can think of some bug might exist"
        end
        @last = ulid

        ulid
      end
    end

    # @raise [TypeError] always raises exception and does not freeze self
    # @return [void]
    def freeze
      raise TypeError, "cannot freeze ULID::MonotonicGenerator"
    end

    private

    # @api private
    # @return [void]
    def reset
      @latest_milliseconds = 0
      @latest_entropy = ULID.reasonable_entropy
      @last = nil
    end
  end
end
