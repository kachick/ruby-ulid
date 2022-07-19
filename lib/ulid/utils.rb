# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

# Copyright (C) 2021 Kenichi Kamiya

require('securerandom')

class ULID
  # @api private
  module Utils
    # @return [Integer]
    def self.current_milliseconds
      milliseconds_from_time(Time.now)
    end

    # @param [Time] time
    # @return [Integer]
    def self.milliseconds_from_time(time)
      (time.to_r * 1000).to_i
    end

    # @param [Time, Integer] moment
    # @return [Integer]
    def self.milliseconds_from_moment(moment)
      case moment
      when Integer
        moment
      when Time
        milliseconds_from_time(moment)
      else
        raise(ArgumentError, '`moment` should be a `Time` or `Integer as milliseconds`')
      end
    end

    # @return [Integer]
    def self.reasonable_entropy
      SecureRandom.random_number(MAX_ENTROPY)
    end

    def self.encode_base32(milliseconds:, entropy:)
      raise(ArgumentError, 'milliseconds and entropy should be an `Integer`') unless Integer === milliseconds && Integer === entropy
      raise(OverflowError, "timestamp overflow: given #{milliseconds}, max: #{MAX_MILLISECONDS}") unless milliseconds <= MAX_MILLISECONDS
      raise(OverflowError, "entropy overflow: given #{entropy}, max: #{MAX_ENTROPY}") unless entropy <= MAX_ENTROPY
      raise(ArgumentError, 'milliseconds and entropy should not be negative') if milliseconds.negative? || entropy.negative?

      base32encoded_timestamp = milliseconds.to_s(32).rjust(TIMESTAMP_ENCODED_LENGTH, '0')
      base32encoded_randomness = entropy.to_s(32).rjust(RANDOMNESS_ENCODED_LENGTH, '0')
      "#{base32encoded_timestamp}#{base32encoded_randomness}"
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
  end

  private_constant(:Utils)
end
