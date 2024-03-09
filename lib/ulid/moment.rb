# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

# Copyright (C) 2021 Kenichi Kamiya

class ULID
  # Almost Time helpers
  module Moment
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
    def self.milliseconds_from(moment)
      case moment
      when Integer
        moment
      when Time
        milliseconds_from_time(moment)
      else
        raise(ArgumentError, '`moment` should be a `Time` or `Integer as milliseconds`')
      end
    end
  end
end
