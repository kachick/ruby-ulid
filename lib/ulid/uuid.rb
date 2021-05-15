# coding: us-ascii
# frozen_string_literal: true
# Copyright (C) 2021 Kenichi Kamiya

# Extracted features around UUID from some reasons
# ref:
#  * https://github.com/kachick/ruby-ulid/issues/105
#  * https://github.com/kachick/ruby-ulid/issues/76
class ULID
  # Imported from https://stackoverflow.com/a/38191104/1212807, thank you!
  UUIDV4_PATTERN = /\A[0-9A-F]{8}-[0-9A-F]{4}-[4][0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}\z/i.freeze
  private_constant :UUIDV4_PATTERN

  # @param [String, #to_str] uuid
  # @return [ULID]
  # @raise [ParserError] if the given format is not correct for UUIDv4 specs
  def self.from_uuidv4(uuid)
    uuid = String.try_convert(uuid)
    raise ArgumentError, 'ULID.from_uuidv4 takes only strings' unless uuid

    prefix_trimmed = uuid.delete_prefix('urn:uuid:')
    unless UUIDV4_PATTERN.match?(prefix_trimmed)
      raise ParserError, "given `#{uuid}` does not match to `#{UUIDV4_PATTERN.inspect}`"
    end

    normalized = prefix_trimmed.gsub(/[^0-9A-Fa-f]/, '')
    from_integer(normalized.to_i(16))
  end

  # @return [String]
  def to_uuidv4
    # This code referenced https://github.com/ruby/ruby/blob/121fa24a3451b45c41ac0a661b64e9fc8600e589/lib/securerandom.rb#L221-L241
    array = octets.pack('C*').unpack('NnnnnN')
    array[2] = (array[2] & 0x0fff) | 0x4000
    array[3] = (array[3] & 0x3fff) | 0x8000
    ('%08x-%04x-%04x-%04x-%04x%08x' % array).freeze
  end
end
