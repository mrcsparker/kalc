require 'kalc'

RSpec::Matchers.define :parse do |source|
  match do |grammar|
    grammar.parse(source)
    true
  rescue Kalc::ParseError => e
    @error = e
    false
  end

  failure_message do
    "expected grammar to parse #{source.inspect}, but it failed with:\n#{@error.message}"
  end

  failure_message_when_negated do
    "expected grammar not to parse #{source.inspect}, but it parsed successfully"
  end
end
