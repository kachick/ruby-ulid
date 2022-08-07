# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

# Copyright (C) 2021 Kenichi Kamiya

require('securerandom')

class ULID
  # @note I don't have confidence for the naming of `Utils`. However some standard libraries have same name.
  #   https://github.com/ruby/webrick/blob/14612a7540fdd7373344461851c4bfff64985b3e/lib/webrick/utils.rb#L17
  #   https://docs.ruby-lang.org/ja/latest/class/ERB=3a=3aUtil.html
  #   https://github.com/ruby/rss/blob/af1c3c9c9630ec0a48abec48ed1ef348ba82aa13/lib/rss/utils.rb#L9
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

    def self.make_sharable_value(value)
      value.freeze
      if defined?(Ractor)
        Ractor.make_shareable(value)
      end
    end

    # @note Call before Module#private_constant
    def self.make_sharable_constantans(mod)
      mod.constants.each do |const_name|
        value = mod.const_get(const_name)
        make_sharable_value(value)
      end
    end

    def self.deprecate(deprecated, replaced)
      warn_kwargs = (RUBY_VERSION >= '3.0') ? { category: :deprecated } : {}
      Warning.warn("#{deprecated} is deprecated. Use #{replaced} instead.", **warn_kwargs)
    end
  end

  private_constant(:Utils)
end
