require 'spec_helper'

describe Kalc::Grammar do
  let(:grammar) { Kalc::Grammar.new }

  context 'integers' do
    1.upto(10) do |i|
      it { grammar.should parse("#{i}") }
    end
  end

  context 'decimal numbers' do
    1.upto(10) do |i|
      1.upto(10) do |n|
        it { grammar.should parse("#{i}.#{n}") }
      end
    end
  end

  context 'basic integer math' do
    1.upto(10) do |i|
      it { grammar.should parse("#{i} - #{i}") }
      it { grammar.should parse("#{i} + #{i}") }
      it { grammar.should parse("#{i} * #{i}") }
      it { grammar.should parse("#{i} / #{i}") }
      it { grammar.should parse("#{i} % #{i}") }
    end
  end

  context 'basic decimal math' do
    1.upto(10) do |i|
      1.upto(10) do |n|
        it { grammar.should parse("#{i}.#{n} - #{i}.#{n}") }
        it { grammar.should parse("#{i}.#{n} + #{i}.#{n}") }
        it { grammar.should parse("#{i}.#{n} * #{i}.#{n}") }
        it { grammar.should parse("#{i}.#{n} / #{i}.#{n}") }
        it { grammar.should parse("#{i}.#{n} % #{i}.#{n}") }
      end
    end
  end

  context 'Logical expressions' do
    it { grammar.should parse('3 && 1') }
    it { grammar.should_not parse('&& 1') }

    it { grammar.should parse('3 || 1') }
    it { grammar.should_not parse('|| 1') }
  end

  context 'Comparison expressions' do
    it { grammar.should parse('3 > 1') }
    it { grammar.should parse('3 < 1') }
    it { grammar.should parse('3 >= 1') }
    it { grammar.should parse('3 <= 1') }

    it { grammar.should_not parse('> 1') }
    it { grammar.should_not parse('< 1') }
    it { grammar.should_not parse('>= 1') }
    it { grammar.should_not parse('<= 1') }
  end

  context 'Equality' do
    it { grammar.should parse('3 == 1') }
    it { grammar.should parse('2 != 1') }
  end

  context 'Block' do
    it { grammar.should parse('(2 + 1)') }
    it { grammar.should parse('(2 + 1) + 1') }
    it { grammar.should parse('(2 + 1) * (1 / 2) + 3') }
    it { grammar.should parse('(2 + 1) + (1 + 2) + ((3 + 2) / (2 + 1)) * 9') }
    it { grammar.should parse('(2 + 1) - (1)') }
    it { grammar.should parse('(2 ) + (  1)') }
    it { grammar.should parse('((2) + (    1 ))') }
  end

  context 'Ternary expressions' do
    it { grammar.should parse('3 > 2 ? 1 : 5') }
    it { grammar.should parse('3 > 2 || 4 <= 5 ? 1 : 5') }
    it { grammar.should parse('(3 > (2 + 4)) ? 1 : 5') }
    it { grammar.should parse('IF(2 > 3, 3 > 2 ? 1 : 5, 7)') }
    it { grammar.should parse('3 > 2 ? 1 : 5 > 4 ? 7 : 5') }
  end

  context 'AND statements' do
    it { grammar.should parse('AND(1, 2, 3)') }
    it { grammar.should parse('AND(1, 2, 3, 4, 5, 6)') }
    it { grammar.should parse('AND(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)') }
  end

  context 'OR statements' do
    it { grammar.should parse('OR(1, 2, 3)') }
    it { grammar.should parse('OR(1, 2, 3, 4, 5, 6)') }
    it { grammar.should parse('OR(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)') }
  end

  context 'IF statements' do
    it { grammar.should parse('IF(3, 2, 1)') }
    it { grammar.should parse('IF(3 > 1, 2, 1)') }
    it { grammar.should parse('IF((3 > 1) || (2 < 1), 2, 1)') }
    it { grammar.should parse('IF(OR(1 > 3, 2 < 5), 3, 2)') }
  end

  context 'Nested IF statements' do
    it { grammar.should parse('IF(3 > 2, IF(2 < 3, 1, 3), 5)') }
    it { grammar.should parse('IF(3 > 2, IF(2 < 3, 1, 3), IF(5 > 1, 3, 9))') }
  end

  context 'MAX statements' do
    it { grammar.should parse('MAX(3, 1, 2)') }
    it { grammar.should parse('MAX(-1, 2*4, (3-1)*2, 5, 6)') }
    it { grammar.should parse('MAX(1, var, 10)') }
  end

  context 'MIN statements' do
    it { grammar.should parse('MIN(3, 1, 2)') }
    it { grammar.should parse('MIN(-1, 2*4, (3-1)*2, 5, 6)') }
    it { grammar.should parse('MIN(1, -var, 10)') }
  end
end
