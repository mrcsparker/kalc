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
  
  it { evaluate("5 / 5").should == 1 }
  
  it { evaluate("5 / 4 / 2").should == 0.625 }
  it { evaluate("5/4/2").should == 0.625 }

  it { evaluate("6 * 2 / 3").should == 4 }

  it { evaluate("10 > 9").should == true }
  it { evaluate("10 < 9").should == false }

  it { evaluate("10 + 19 + 11 * 3").should == 62 }

  it { evaluate("10 >= 10").should == true }

  it "should be able to load variables" do
    evaluate("a = 1; 1 + a").should == 2
    evaluate("a = 1; b = 2; 1 + b").should == 3
  end

  it "should be able to load single quoted variables" do
    evaluate("'a' = 1; 1 + 'a'").should == 2
    evaluate("'a' = 1; 'b' = 2; 'b' + 'a'").should == 3
  
    evaluate("'a b' = 1; 'a b' + 1").should == 2
  end

  it { evaluate("((75.0)*(25.0))+((125.0)*(25.0))+((150.0)*(25.0))+((250.0)*(25.0))").should == 15000 }

  it { evaluate("(((40.0)/1000*(4380.0)*(200.0))-((40.0)/1000*(4380.0)*((((75.0)*(25.0))+((125.0)*(25.0))+((150.0)*(25.0))+((250.0)*(25.0)))/(10.0)/(40.0)/(0.8))))*(0.05)").should == 1341.375 }

  private
  def evaluate(expression)
    g = @grammar.parse(expression)
    ast = @transform.apply(g)
    Kalc::Interpreter.new.run(ast)
  end
end
