require 'spec_helper'

describe Kalc::Interpreter do
  before(:each) do
    @grammar = Kalc::Grammar.new
    @transform = Kalc::Transform.new
  end

  it { evaluate("2 + 2").should == 4 }
  it { evaluate("1 + 1").should == 2.0 }
  it { evaluate("4 + 1").should == 5 }
  it { evaluate("5 + 5").should == 10 }

  it { evaluate("10 > 9").should == true }
  it { evaluate("10 < 9").should == false }

  it { evaluate("10 + 19 + 11 * 3").should == 62 }

  it { evaluate("10 >= 10").should == true }

  private
  def evaluate(expression)
    g = @grammar.parse(expression)
    ast = @transform.apply(g)
    Kalc::Interpreter.new(ast).run
  end
end
