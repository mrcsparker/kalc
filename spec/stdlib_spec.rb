require 'spec_helper'

class Kalc::Stdlib

end

describe Kalc::Stdlib do

  before(:each) do
    @grammar = Kalc::Grammar.new
    @transform = Kalc::Transform.new
  end

  describe 'PLUS_ONE' do
    it { expect(evaluate('PLUS_ONE(1)')).to eq(2) }
    it { expect(evaluate('PLUS_ONE(101)')).to eq(102) }
    it { expect(evaluate('PLUS_ONE(0)')).to eq(1) }
    it { expect(evaluate('PLUS_ONE(-1)')).to eq(0) }
  end

  describe 'MINUS_ONE' do
    it { expect(evaluate('MINUS_ONE(1)')).to eq(0) }
    it { expect(evaluate('MINUS_ONE(101)')).to eq(100) }
    it { expect(evaluate('MINUS_ONE(0)')).to eq(-1) }
    it { expect(evaluate('MINUS_ONE(-1)')).to eq(-2) }
  end

  describe 'SQUARE' do
    it { expect(evaluate('SQUARE(2)')).to eq(4) }
    it { expect(evaluate('SQUARE(4)')).to eq(16) }
  end

  describe 'CUBE' do
    it { expect(evaluate('CUBE(2)')).to eq(8) }
    it { expect(evaluate('CUBE(4)')).to eq(64) }
  end

  describe 'FIB' do
    it { expect(evaluate('FIB(1)')).to eq(1) }
    it { expect(evaluate('FIB(10)')).to eq(55) }
  end

  describe 'FACTORIAL' do
    it { expect(evaluate('FACTORIAL(1)')).to eq(1) }
    it { expect(evaluate('FACTORIAL(5)')).to eq(120) }
  end

  describe 'TOWERS_OF_HANOI' do
    it { expect(evaluate('TOWERS_OF_HANOI(4)')).to eq(15) }
    it { expect(evaluate('TOWERS_OF_HANOI(10)')).to eq(1023) }
  end

  private
  def evaluate(expression)
    r = Kalc::Runner.new
    r.run(expression)
  end
end
