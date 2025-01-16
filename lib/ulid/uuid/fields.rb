# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

# Copyright (C) 2021 Kenichi Kamiya

class ULID
  module UUID
    # @see https://www.rfc-editor.org/rfc/rfc4122#section-4.1.2
    # @note
    #   - Using `Fields = Data.define do; end` syntax made https://github.com/kachick/ruby-ulid/issues/233 again. So use class syntax instead
    #   - This file is extracted to avoid YARD warnings "Ruby::ClassHandler: Undocumentable superclass" https://github.com/lsegal/yard/issues/737
    #     Partially avoiding is hard in YARD, so extracting the code and using exclude filter in yardopts...
    class Fields < Data.define(:time_low, :time_mid, :time_hi_and_version, :clock_seq_hi_and_res, :clk_seq_low, :node)
      def self.raw_from_octets(octets)
        case octets.pack('C*').unpack('NnnnnN')
        in [Integer => time_low, Integer => time_mid, Integer => time_hi_and_version, Integer => clock_seq_hi_and_res, Integer => clk_seq_low, Integer => node]
          new(time_low:, time_mid:, time_hi_and_version:, clock_seq_hi_and_res:, clk_seq_low:, node:).freeze
        end
      end

      def self.forced_version_from_octets(octets, mask:)
        case octets.pack('C*').unpack('NnnnnN')
        in [Integer => time_low, Integer => time_mid, Integer => time_hi_and_version, Integer => clock_seq_hi_and_res, Integer => clk_seq_low, Integer => node]
          new(
            time_low:,
            time_mid:,
            time_hi_and_version: (time_hi_and_version & 0x0fff) | mask,
            clock_seq_hi_and_res: (clock_seq_hi_and_res & 0x3fff) | 0x8000,
            clk_seq_low:,
            node:
          ).freeze
        end
      end

      def to_s
        '%08x-%04x-%04x-%04x-%04x%08x' % deconstruct
      end
    end
  end
end
