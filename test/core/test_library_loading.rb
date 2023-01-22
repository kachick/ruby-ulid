# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestLibraryLoading < Test::Unit::TestCase
  def test_naming_convention_for_bundler
    assert_true(require_relative('../../lib/ruby-ulid'))
  end

  compilable_paths = Dir.glob('lib/**/*.rb')
  raise unless compilable_paths.size >= 5

  compilable_paths.each do |path|
    data(path, path)
  end
  def test_vm_compilable(path)
    assert_instance_of(String, RubyVM::InstructionSequence.compile_file(path).to_binary)
  end
end
