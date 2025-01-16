# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

# Copyright (C) 2021 Kenichi Kamiya

require('securerandom')

class ULID
  module Utils
    # @return [Integer]
    def self.current_milliseconds
      # There are different recommendations for this featrure with the accuracy and other context
      # At here, I prefer to adjust with Ruby UUID v7 imeplementation and respect monotonicity use-case
      # https://github.com/ruby/securerandom/pull/19/files#diff-cad52e37612706fe31d85599bb8bc789e90fd382f091ed31fdd036119af3e5cdR252
      # Other resources
      #   - https://blog.dnsimple.com/2018/03/elapsed-time-with-ruby-the-right-way/
      #   - https://github.com/ruby/ruby/blob/5df20ab0b49b55c9cf858879f3e6e30cc3dcd803/process.c#L8131
      Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond)
    end

    # @param [Time, Integer] moment
    # @return [Integer]
    def self.milliseconds_from_moment(moment)
      case moment
      when Integer
        moment
      when Time
        (moment.to_r * 1000).to_i
      else
        raise(ArgumentError, '`moment` should be a `Time` or `Integer as milliseconds`')
      end
    end

    # @return [Integer]
    def self.reasonable_entropy
      SecureRandom.random_number(MAX_ENTROPY)
    end

    # @param [Integer] milliseconds
    # @param [Integer] entropy
    # @return [String]
    # @raise [OverflowError] if the given value is larger than the ULID limit
    # @raise [ArgumentError] if the given milliseconds and/or entropy is negative number
    def self.encode_base32hex(milliseconds:, entropy:)
      raise(ArgumentError, 'milliseconds and entropy should be an `Integer`') unless Integer === milliseconds && Integer === entropy
      raise(OverflowError, "timestamp overflow: given #{milliseconds}, max: #{MAX_MILLISECONDS}") unless milliseconds <= MAX_MILLISECONDS
      raise(OverflowError, "entropy overflow: given #{entropy}, max: #{MAX_ENTROPY}") unless entropy <= MAX_ENTROPY
      raise(ArgumentError, 'milliseconds and entropy should not be negative') if milliseconds.negative? || entropy.negative?

      base32hex_timestamp = milliseconds.to_s(32).rjust(TIMESTAMP_ENCODED_LENGTH, '0')
      base32hex_randomness = entropy.to_s(32).rjust(RANDOMNESS_ENCODED_LENGTH, '0')
      "#{base32hex_timestamp}#{base32hex_randomness}"
    end

    # @param [BasicObject] object
    # @return [String]
    def self.safe_get_class_name(object)
      fallback = 'UnknownObject'

      # This class getter implementation used https://github.com/rspec/rspec-support/blob/4ad8392d0787a66f9c351d9cf6c7618e18b3d0f2/lib/rspec/support.rb#L83-L89 as a reference, thank you!
      # ref: https://twitter.com/_kachick/status/1400064896759304196
      klass = (
        begin
          object.class
        rescue NoMethodError
          # steep can't correctly handle singleton class assign. See https://github.com/soutaro/steep/pull/586 for further detail
          # So this annotation is hack for the type infer.
          # @type var object: BasicObject
          # @type var singleton_class: untyped
          singleton_class = class << object; self; end
          (Class === singleton_class) ? singleton_class.ancestors.detect { |ancestor| !ancestor.equal?(singleton_class) } : fallback
        end
      )

      begin
        name = String.try_convert(klass.name)
      rescue Exception
        fallback
      else
        name || fallback
      end
    end

    # @note Call before Module#private_constant
    def self.make_sharable_constants(mod)
      mod.constants.each do |const_name|
        value = mod.const_get(const_name)
        Ractor.make_shareable(value)
      end
    end
  end

  private_constant(:Utils)
end
