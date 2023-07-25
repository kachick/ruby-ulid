#!/usr/bin/env ruby
# frozen_string_literal: true

# Keep no runtime dependencies except ruby bundled

require('irb')
require('irb/completion') # easy tab completion ref: https://docs.ruby-lang.org/ja/latest/library/irb=2fcompletion.html

require_relative('../lib/ulid')

IRB.start
