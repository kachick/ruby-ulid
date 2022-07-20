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

    undef_method(:instance_variable_set)

    # @return [String]
    def inspect
      "ULID::MonotonicGenerator(prev: #{prev.inspect})"
    end
    alias_method(:to_s, :inspect)

    # @param [Time, Integer] moment
    # @return [String]
    def generate(moment: Utils.current_milliseconds)
      bump(moment: moment) do |milliseconds:, entropy:|
        ulid = ULID.generate(moment: milliseconds, entropy: entropy)
        [ulid, -> { ulid.inspect }]
      end
    end

    # @param [Time, Integer] moment
    # @return [String]
    def encode(moment: Utils.current_milliseconds)
      bump(moment: moment) do |milliseconds:, entropy:|
        encoded = ULID.encode(moment: milliseconds, entropy: entropy)
        [encoded, -> { ULID.parse(encoded).inspect }]
      end
    end

    undef_method(:freeze)

    # @raise [TypeError] always raises exception and does not freeze self
    # @return [void]
    def freeze
      raise(TypeError, "cannot freeze #{self.class}")
    end

    # @return [ULID, nil]
    def prev
      msec, entropy, encoded = @prev_milliseconds, @prev_entropy, @prev_encoded
      msec && entropy && encoded && ULID.generate(moment: msec, entropy: entropy)
    end

    private

    def initialize
      super
      @prev_milliseconds = nil
      @prev_entropy = nil
      @prev_encoded = nil
    end

    def rewind(prev_ulid: nil)
      @prev_milliseconds = prev_ulid&.milliseconds
      @prev_entropy = prev_ulid&.entropy
      @prev_encoded = prev_ulid&.encode
    end

    def bump(moment:)
      synchronize do
        current_msec = Utils.milliseconds_from_moment(moment)

        # Don't use reader methods
        prev_msec = @prev_milliseconds
        prev_ent = @prev_entropy
        prev_enc = @prev_encoded
        current_entropy = Utils.reasonable_entropy

        unless prev_msec && prev_ent && prev_enc
          result, = yield(milliseconds: current_msec, entropy: current_entropy)
          @prev_milliseconds = current_msec
          @prev_entropy = current_entropy
          @prev_encoded = result.to_s
          return result
        end

        if current_msec > prev_msec
          determined_msec = current_msec
          determined_entropy = current_entropy
        else
          determined_msec = prev_msec
          determined_entropy = prev_ent.succ
        end

        result, inspector = yield(milliseconds: determined_msec, entropy: determined_entropy)
        encoded = result.to_s

        unless encoded > prev_enc
          base_message = "monotonicity broken from unexpected reasons # generated: #{inspector.call}, prev: #{ULID.parse(prev_enc).inspect}"
          additional_information = (
            if Thread.list == [Thread.main]
              '# NOTE: looks single thread only exist'
            else
              '# NOTE: ran on multi threads, so this might from concurrency issue'
            end
          )

          raise(UnexpectedError, base_message + additional_information)
        end

        @prev_milliseconds = determined_msec
        @prev_entropy = determined_entropy
        @prev_encoded = encoded
        result
      end
    end
  end
end
