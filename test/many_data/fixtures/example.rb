# coding: utf-8
# frozen_string_literal: true

# The to_time should be less than 10000: https://github.com/toml-lang/toml/blob/2431aa308a7bc97eeb50673748606e23a6e0f201/toml.abnf#L180
# period is derepcated since it cannot be serialize in TOML
Example = Data.define(:string, :integer, :timestamp, :randomness, :to_time, :inspect, :uuidish, :uuidv4, :octets)
