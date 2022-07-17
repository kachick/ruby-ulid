# coding: us-ascii
# frozen_string_literal: true

require 'stackprof'
require_relative '../lib/ulid'

StackProf.run(mode: :cpu, out: "./tmp/stackprof-cpu-#{Time.now.to_i}.dump") do
  100000.times { ULID.encode }
end
