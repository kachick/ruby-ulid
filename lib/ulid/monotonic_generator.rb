# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

# Copyright (C) 2021 Kenichi Kamiya

require_relative('errors')
require_relative('utils')

class ULID
  class MonotonicGenerator
    # @note When use https://github.com/ko1/ractor-tvar might realize Ractor based thread safe monotonic generator.
    #       However it is a C extention, I'm pending to use it for now.
    include(MonitorMixin)

    # @return [ULID, nil]
    attr_accessor(:last)
    private(:last=)

    undef_method(:instance_variable_set)

    def initialize
      super
      @last = nil
    end

    # @return [String]
    def inspect
      "ULID::MonotonicGenerator(last: #{@last.inspect})"
    end
    alias_method(:to_s, :inspect)

    # @param [Time, Integer] moment
    # @return [ULID]
    # @raise [OverflowError] if the entropy part is larger than the ULID limit in same milliseconds
    # @raise [UnexpectedError] if the generated ULID is an invalid value in monotonicity spec.
    #   Basically will not happen. Just means this feature prefers error rather than invalid value.
    def generate(moment: Utils.current_milliseconds)
      synchronize do
        prev = @last
        unless prev
          ret = ULID.generate(moment:)
          @last = ret
          return ret
        end

        milliseconds = Utils.milliseconds_from_moment(moment)

        ulid = (
          if prev.milliseconds < milliseconds
            ULID.generate(moment: milliseconds)
          else
            ULID.generate(moment: prev.milliseconds, entropy: prev.entropy.succ)
          end
        )

        unless ulid > prev
          base_message = "monotonicity broken from unexpected reasons # generated: #{ulid.inspect}, prev: #{prev.inspect}"
          additional_information = (
            if Thread.list == [Thread.main]
              '# NOTE: looks single thread only exist'
            else
              '# NOTE: ran on multi threads, so this might from concurrency issue'
            end
          )

          raise(UnexpectedError, base_message + additional_information)
        end

        @last = ulid
        ulid
      end
    end

    # Just providing similar api as `ULID.generate` and `ULID.encode` relation. No performance benefit exists in monotonic generator's one.
    #
    # @see https://github.com/kachick/ruby-ulid/pull/220
    # @param [Time, Integer] moment
    # @return [String]
    def encode(moment: Utils.current_milliseconds)
      generate(moment:).encode
    end

    undef_method(:freeze)

    # @raise [TypeError] always raises exception and does not freeze self
    # @return [void]
    def freeze
      raise(TypeError, "cannot freeze #{self.class}")
    end
  end
end
