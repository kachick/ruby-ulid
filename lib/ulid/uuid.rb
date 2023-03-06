# coding: us-ascii
# frozen_string_literal: true

# Copyright (C) 2021 Kenichi Kamiya

require_relative('errors')

# Extracted features around UUID from some reasons
# ref:
#  * https://github.com/kachick/ruby-ulid/issues/105
#  * https://github.com/kachick/ruby-ulid/issues/76
class ULID
  # Imported from https://stackoverflow.com/a/38191104/1212807, thank you!
  UUIDV4_PATTERN = /\A[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}\z/i
  UUIDish =
    # https://github.com/ruby/rbs/issues/627#issuecomment-797330517
    _ =
      # @todo Replace to Data class after dropped Ruby 3.1
      Struct.new(:time_low, :time_mid, :time_hi_and_version, :clock_seq_hi_and_res, :clk_seq_low, :node, keyword_init: true) do
        # @implements UUIDish

        def self.from_bytes(bytes)
          case bytes.pack('C*').unpack('NnnnnN')
          in [Integer => time_low, Integer => time_mid, Integer => time_hi_and_version, Integer => clock_seq_hi_and_res, Integer => clk_seq_low, Integer => node]
            new(time_low:, time_mid:, time_hi_and_version:, clock_seq_hi_and_res:, clk_seq_low:, node:).freeze
          end
        end

        def to_s
          '%08x-%04x-%04x-%04x-%04x%08x' % values
        end
      end
  class MalformedUUIDError < Error; end
  Ractor.make_shareable(UUIDV4_PATTERN)
  private_constant(:UUIDV4_PATTERN)

  # Provided for ULID and UUID converting vice versa with ignoring UUID version and variant spec
  # @return [String]
  def to_uuidish
    UUIDish.from_bytes(bytes).to_s.freeze
  end

  # @param [String, #to_str] uuid
  # @return [ULID]
  # @raise [ParserError] if the given format is not correct for UUIDv4 specs
  def self.from_uuidv4(uuid)
    uuid = String.try_convert(uuid)
    raise(ArgumentError, 'ULID.from_uuidv4 takes only strings') unless uuid

    prefix_trimmed = uuid.delete_prefix('urn:uuid:')
    unless UUIDV4_PATTERN.match?(prefix_trimmed)
      raise(ParserError, "given `#{uuid}` does not match to `#{UUIDV4_PATTERN.inspect}`")
    end

    normalized = prefix_trimmed.gsub(/[^0-9A-Fa-f]/, '')
    from_integer(normalized.to_i(16))
  end

  # Convert the ULID to UUIDv4 that will have version and variants field
  # Some boundary case, they cannot be restore original ULID, if it is needed, use `#to_uuidish` instead
  # @return [String]
  def to_uuidv4(force: true)
    uuidish = UUIDish.from_bytes(bytes)
    v4 = UUIDish.new(
      **uuidish.to_h,
      # This replacing 2 fields logic was referenced to https://github.com/ruby/ruby/blob/84150e6901ad0599d7bcbab34aed2f20235959ff/lib/random/formatter.rb#L172-L173
      time_hi_and_version: (uuidish.time_hi_and_version & 0x0fff) | 0x4000,
      clock_seq_hi_and_res: (uuidish.clock_seq_hi_and_res & 0x3fff) | 0x8000
    )
    raise(MalformedUUIDError) unless (uuidish == v4) || force

    v4.to_s.freeze
  end
end
