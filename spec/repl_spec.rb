require 'spec_helper'

describe Kalc::Repl do
  subject(:repl) { described_class.new }

  before do
    repl.load_env
  end

  it 'reports security errors without leaving the REPL loop' do
    expect do
      expect(repl.send(:process_input, 'SYSTEM("echo nope")')).to eq(:continue)
    end.to output("SecurityError: SYSTEM is disabled\n").to_stdout
  end
end
