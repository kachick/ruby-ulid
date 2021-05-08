# coding: us-ascii
# frozen_string_literal: true

require 'warning'

# How to use => https://test-unit.github.io/test-unit/en/
require 'test/unit'

if Warning.respond_to?(:[]=) # @TODO Removable this guard after dropped ruby 2.6
  Warning[:deprecated] = true
  Warning[:experimental] = true
end

Warning.process do |warning|
  :raise
end

require_relative '../lib/ulid'

module ULIDAssertions
  # Taken the features of https://github.com/ruby/did_you_mean/blob/fbe5aaaae8405d19dc1bf691c5bead6348c6da10/lib/did_you_mean/levenshtein.rb :yum:

  def assert_acceptable_timestamp_string(a, b)
    distance = DidYouMean::Levenshtein.distance(a, b)
    acceptable = (ULID::TIMESTAMP_ENCODED_LENGTH - 5)..ULID::TIMESTAMP_ENCODED_LENGTH
    assert(acceptable.cover?(distance), "#{a} vs #{b} => #{distance} is not in #{acceptable}, needed to check the randomness is not broken in `timestamp` part!")
  end

  def assert_acceptable_randomness_string(a, b)
    distance = DidYouMean::Levenshtein.distance(a, b)
    acceptable = (ULID::RANDOMNESS_ENCODED_LENGTH - 5)..ULID::RANDOMNESS_ENCODED_LENGTH
    assert(acceptable.cover?(distance), "#{a} vs #{b} => #{distance} is not in #{acceptable}, needed to check the randomness is not broken in `randomness` part!")
  end
end
