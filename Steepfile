# frozen_string_literal: true

target(:lib) do
  signature('sig')

  check('lib')

  library('securerandom', 'monitor')

  configure_code_diagnostics(Steep::Diagnostic::Ruby::ElseOnExhaustiveCase => :information)
end
