# frozen_string_literal: true

require('ulid')

ulid = ULID.generate
p ulid.to_time
