# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

# Copyright (C) 2021 Kenichi Kamiya

class ULID
  class MonotonicGenerator
    # @note When use https://github.com/ko1/ractor-tvar might realize Ractor based thread safe monotonic generator.
    #       However it is a C extention, I'm pending to use it for now.
    include(MonitorMixin)

    # @dynamic prev
    # @return [ULID, nil]
    attr_reader(:prev)

    undef_method(:instance_variable_set)

    def initialize
      super
      @prev = nil
    end

    # @return [String]
    def inspect
      "ULID::MonotonicGenerator(prev: #{@prev.inspect})"
    end
    # @dynamic to_s
    alias_method(:to_s, :inspect)

    # @param [Time, Integer] moment
    # @return [ULID]
    # @raise [OverflowError] if the entropy part is larger than the ULID limit in same milliseconds
    # @raise [UnexpectedError] if the generated ULID is an invalid value in monotonicity spec.
    #   Basically will not happen. Just means this feature prefers error rather than invalid value.
    def generate(moment: ULID.current_milliseconds)
      synchronize do
        prev_ulid = @prev
        unless prev_ulid
          ret = ULID.generate(moment: moment)
          @prev = ret
          return ret
        end

        milliseconds = ULID.milliseconds_from_moment(moment)

        ulid = (
          if prev_ulid.milliseconds < milliseconds
            ULID.generate(moment: milliseconds)
          else
            ULID.from_milliseconds_and_entropy(milliseconds: prev_ulid.milliseconds, entropy: prev_ulid.entropy.succ)
          end
        )

        unless ulid > prev_ulid
          base_message = "monotonicity broken from unexpected reasons # generated: #{ulid.inspect}, prev: #{prev_ulid.inspect}"
          additional_information = (
            if Thread.list == [Thread.main]
              '# NOTE: looks single thread only exist'
            else
              '# NOTE: ran on multi threads, so this might from concurrency issue'
            end
          )

          raise(UnexpectedError, base_message + additional_information)
        end

        @prev = ulid
        ulid
      end
    end

    # @TODO Consider to provide this
    # def encode
    # end

    undef_method(:freeze)

    # @raise [TypeError] always raises exception and does not freeze self
    # @return [void]
    def freeze
      raise(TypeError, "cannot freeze #{self.class}")
    end
  end
end
