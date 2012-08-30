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

  it { evaluate("ABS(-1 + -2)").should == 3 }

  it "should be able to load variables" do
    evaluate("a := 1; 1 + a").should == 2
    evaluate("a := 1; b := 2; 1 + b").should == 3
  end

  it "should be able to load quoted variables" do
    evaluate("'Item (a)' := 1; 1 + 'Item (a)'").should == 2
    evaluate("'a' := 1; 'b[a]' := 2 + 'a'; 1 + 'b[a]'").should == 4
  end

  it "should be able to load single quoted variables" do
    evaluate("'a' := 1; 1 + 'a'").should == 2
    evaluate("'a' := 1; 'b' := 2; 'b' + 'a'").should == 3
  
    evaluate("'a b' := 1; 'a b' + 1").should == 2
  end

  it { evaluate("((75.0)*(25.0))+((125.0)*(25.0))+((150.0)*(25.0))+((250.0)*(25.0))").should == 15000 }

  it { evaluate("(((40.0)/1000*(4380.0)*(200.0))-((40.0)/1000*(4380.0)*((((75.0)*(25.0))+((125.0)*(25.0))+((150.0)*(25.0))+((250.0)*(25.0)))/(10.0)/(40.0)/(0.8))))*(0.05)").should == 1341.375 }

  context "Negative numbers" do
    it { evaluate("-2").should == -2 }
    it { evaluate("-1000").should == -1000 }
    it { evaluate("-1000.0001").should == -1000.0001 }
    it { evaluate("1 + -1").should == 0 }
    it { evaluate("1 + -10").should == -9 }
  end

  context "Positive numbers" do
    it { evaluate("1 + +1").should == 2 }
    it { evaluate("1 + +1 - 1").should == 1 }
    it { evaluate("+10000.0001").should == 10000.0001 }
  end

  context "Boolean value" do
    it { evaluate("TRUE").should == true }
    it { evaluate("FALSE").should == false }
    it { evaluate("FALSE || TRUE").should == true }
    it { evaluate("FALSE && TRUE").should == false }
  end

  context "Floating point number" do
    it { evaluate("1.01").should == 1.01 }
    it { evaluate("1.01 + 0.02").should == 1.03 }
    it { evaluate("1.01 - 0.01").should == 1 }
    it { evaluate("1.1 + 1.1").should == 2.2 }
    it { evaluate("1.01 = 1.01").should == true }
    it { evaluate("1.01 = 1.02").should == false }
  end

  context "Exponents" do
    it { evaluate("1.23e+10").should == 12300000000.0 }
    it { evaluate("1.23e-10").should == 1.23e-10 }
  end

  context "Numbers starting with a decimal point" do
    it { evaluate("0.4").should == 0.4 }
    it { evaluate(".4").should == 0.4 }
  end

  private
  def evaluate(expression)
    g = @grammar.parse(expression)
    ast = @transform.apply(g)
    Kalc::Interpreter.new.run(ast)
  end
end
