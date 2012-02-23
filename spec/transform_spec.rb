require 'spec_helper'

describe Kalc::Transform do
  let(:grammar) { Kalc::Grammar.new }
  let(:ts) { Kalc::Transform.new }

  context "integers" do
    1.upto(10) do |i|
      it { ts.apply(grammar.parse("#{i}")).should == i }
    end
  end

  context "floats" do
    1.upto(10) do |i|
      1.upto(10) do |n|
        it { ts.apply(grammar.parse("#{i}.#{n}")).should == Float("#{i}.#{n}") }
      end
    end
  end

  context "basic integer math" do
    1.upto(10) do |i|
      it { ts.apply(grammar.parse("#{i} - #{i}")).should == (i - i) }
      it { ts.apply(grammar.parse("#{i} + #{i}")).should == (i + i) }
      it { ts.apply(grammar.parse("#{i} * #{i}")).should == (i * i) }
      it { ts.apply(grammar.parse("#{i} / #{i}")).should == (i / i) }
      it { ts.apply(grammar.parse("#{i} % #{i}")).should == (i % i) }
    end
  end

  context "basic float math" do
    1.upto(10) do |i|
      1.upto(10) do |n|
        it { ts.apply(grammar.parse("#{i}.#{n} - #{i}.#{n}")).should == (Float("#{i}.#{n}") - Float("#{i}.#{n}")) }
        it { ts.apply(grammar.parse("#{i}.#{n} + #{i}.#{n}")).should == (Float("#{i}.#{n}") + Float("#{i}.#{n}")) }
        it { ts.apply(grammar.parse("#{i}.#{n} * #{i}.#{n}")).should == (Float("#{i}.#{n}") * Float("#{i}.#{n}")) }
        it { ts.apply(grammar.parse("#{i}.#{n} / #{i}.#{n}")).should == (Float("#{i}.#{n}") / Float("#{i}.#{n}")) }
        it { ts.apply(grammar.parse("#{i}.#{n} % #{i}.#{n}")).should == (Float("#{i}.#{n}") % Float("#{i}.#{n}")) }
      end
    end
  end

  context "Comparison expressions" do
    it { ts.apply(grammar.parse("3 > 1")).should == true }
    it { ts.apply(grammar.parse("3 > 5")).should == false }
    it { ts.apply(grammar.parse("3 == 5")).should == false }
    it { ts.apply(grammar.parse("3 != 5")).should == true }
    it { ts.apply(grammar.parse("2 >= 2")).should == true }
    it { ts.apply(grammar.parse("2 <= 2")).should == true }
    it { ts.apply(grammar.parse("2 < 2")).should == false }
  end

  context "AND statement" do
    it { p grammar.parse("AND(3 > 2, 1 < 3)") }
    it { ts.apply(grammar.parse("AND(3 > 2, 1 < 3)")).should == true }
  end

end
