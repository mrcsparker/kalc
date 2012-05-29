require 'spec_helper'

class Kalc::Stdlib

end

describe Kalc::Stdlib do
  
  before(:each) do
    @grammar = Kalc::Grammar.new
    @transform = Kalc::Transform.new
  end

  describe "PLUS_ONE" do
    it { evaluate("PLUS_ONE(1)").should == 2 }
    it { evaluate("PLUS_ONE(101)").should == 102 }
    it { evaluate("PLUS_ONE(0)").should == 1 }
    it { evaluate("PLUS_ONE(-1)").should == 0 }
  end

  describe "MINUS_ONE" do
    it { evaluate("MINUS_ONE(1)").should == 0 }
    it { evaluate("MINUS_ONE(101)").should == 100 }
    it { evaluate("MINUS_ONE(0)").should == -1 }
    it { evaluate("MINUS_ONE(-1)").should == -2 }
  end

  describe "SQUARE" do
    it { evaluate("SQUARE(2)").should == 4 }
    it { evaluate("SQUARE(4)").should == 16 }
  end

  describe "CUBE" do
    it { evaluate("CUBE(2)").should == 8 }
    it { evaluate("CUBE(4)").should == 64 }
  end

  describe "FIB" do
    it { evaluate("FIB(1)").should == 1 }
    it { evaluate("FIB(10)").should == 55 }
  end

  describe "FACTORIAL" do
    it { evaluate("FACTORIAL(1)").should == 1 }
    it { evaluate("FACTORIAL(5)").should == 120 }
  end

  describe "TOWERS_OF_HANOI" do
    it { evaluate("TOWERS_OF_HANOI(4)").should == 15 }
    it { evaluate("TOWERS_OF_HANOI(10)").should == 1023 }
  end

  private
  def evaluate(expression)
    r = Kalc::Runner.new
    r.run(expression)
  end
end
