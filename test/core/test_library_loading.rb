# coding: utf-8
# frozen_string_literal: true

require_relative '../helper'

class TestLibraryLoading < Test::Unit::TestCase
  def test_naming_convention_for_bundler
    assert_true(require_relative('../../lib/ruby-ulid'))
  end
end
