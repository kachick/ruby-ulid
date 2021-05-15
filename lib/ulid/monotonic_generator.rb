# coding: us-ascii
# frozen_string_literal: true
# Copyright (C) 2021 Kenichi Kamiya

class ULID
  class MonotonicGenerator
    # @return [ULID, nil]
    attr_reader :prev

    undef_method :instance_variable_set

    def initialize
      @mutex = Thread::Mutex.new
      @prev = nil
    end

    # @return [String]
    def inspect
      "ULID::MonotonicGenerator(prev: #{@prev.inspect})"
    end
    alias_method :to_s, :inspect

    # @param [Time, Integer] moment
    # @return [ULID]
    # @raise [OverflowError] if the entropy part is larger than the ULID limit in same milliseconds
    # @raise [UnexpectedError] if the generated ULID is an invalid value in monotonicity spec.
    #   Basically will not happen. Just means this feature prefers error rather than invalid value.
    def generate(moment: ULID.current_milliseconds)
      @mutex.synchronize do
        unless @prev
          @prev = ULID.generate(moment: moment)
          return @prev
        end

        milliseconds = ULID.milliseconds_from_moment(moment)

        ulid = if @prev.milliseconds < milliseconds
          ULID.generate(moment: milliseconds)
        else
          ULID.from_milliseconds_and_entropy(milliseconds: @prev.milliseconds, entropy: @prev.entropy.succ)
        end

        unless ulid > @prev
          base_message = "monotonicity broken from unexpected reasons # generated: #{ulid.inspect}, prev: #{@prev.inspect}"
          additional_information = if Thread.list == [Thread.main]
            '# NOTE: looks single thread only exist'
          else
            '# NOTE: ran on multi threads, so this might from concurrency issue'
          end

          raise UnexpectedError, base_message + additional_information
        end

        @prev = ulid
        ulid
      end
    end

    undef_method :freeze

    # @raise [TypeError] always raises exception and does not freeze self
    # @return [void]
    def freeze
      raise TypeError, "cannot freeze #{self.class}"
    end
  end
end
