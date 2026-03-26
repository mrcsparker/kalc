require 'spec_helper'

describe Kalc::Grammar do
  let(:grammar) { Kalc::Grammar.new }

  context 'integers' do
    1.upto(10) do |i|
      it { expect(grammar).to parse(i.to_s) }
    end
  end

  context 'decimal numbers' do
    1.upto(10) do |i|
      1.upto(10) do |n|
        it { expect(grammar).to parse("#{i}.#{n}") }
      end
    end
  end

  context 'basic integer math' do
    1.upto(10) do |i|
      it { expect(grammar).to parse("#{i} - #{i}") }
      it { expect(grammar).to parse("#{i} + #{i}") }
      it { expect(grammar).to parse("#{i} * #{i}") }
      it { expect(grammar).to parse("#{i} / #{i}") }
      it { expect(grammar).to parse("#{i} % #{i}") }
    end
  end

  context 'basic decimal math' do
    1.upto(10) do |i|
      1.upto(10) do |n|
        it { expect(grammar).to parse("#{i}.#{n} - #{i}.#{n}") }
        it { expect(grammar).to parse("#{i}.#{n} + #{i}.#{n}") }
        it { expect(grammar).to parse("#{i}.#{n} * #{i}.#{n}") }
        it { expect(grammar).to parse("#{i}.#{n} / #{i}.#{n}") }
        it { expect(grammar).to parse("#{i}.#{n} % #{i}.#{n}") }
      end
    end
  end

  context 'Logical expressions' do
    it { expect(grammar).to parse('3 && 1') }
    it { expect(grammar).to_not parse('&& 1') }

    it { expect(grammar).to parse('3 || 1') }
    it { expect(grammar).to_not parse('|| 1') }
  end

  context 'Comparison expressions' do
    it { expect(grammar).to parse('3 > 1') }
    it { expect(grammar).to parse('3 < 1') }
    it { expect(grammar).to parse('3 >= 1') }
    it { expect(grammar).to parse('3 <= 1') }

    it { expect(grammar).to_not parse('> 1') }
    it { expect(grammar).to_not parse('< 1') }
    it { expect(grammar).to_not parse('>= 1') }
    it { expect(grammar).to_not parse('<= 1') }
  end

  context 'Equality' do
    it { expect(grammar).to parse('3 == 1') }
    it { expect(grammar).to parse('2 != 1') }
  end

  context 'Block' do
    it { expect(grammar).to parse('(2 + 1)') }
    it { expect(grammar).to parse('(2 + 1) + 1') }
    it { expect(grammar).to parse('(2 + 1) * (1 / 2) + 3') }
    it { expect(grammar).to parse('(2 + 1) + (1 + 2) + ((3 + 2) / (2 + 1)) * 9') }
    it { expect(grammar).to parse('(2 + 1) - (1)') }
    it { expect(grammar).to parse('(2 ) + (  1)') }
    it { expect(grammar).to parse('((2) + (    1 ))') }
  end

  context 'Ternary expressions' do
    it { expect(grammar).to parse('3 > 2 ? 1 : 5') }
    it { expect(grammar).to parse('3 > 2 || 4 <= 5 ? 1 : 5') }
    it { expect(grammar).to parse('(3 > (2 + 4)) ? 1 : 5') }
    it { expect(grammar).to parse('IF(2 > 3, 3 > 2 ? 1 : 5, 7)') }
    it { expect(grammar).to parse('3 > 2 ? 1 : 5 > 4 ? 7 : 5') }
  end

  context 'AND statements' do
    it { expect(grammar).to parse('AND(1, 2, 3)') }
    it { expect(grammar).to parse('AND(1, 2, 3, 4, 5, 6)') }
    it { expect(grammar).to parse('AND(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)') }
  end

  context 'OR statements' do
    it { expect(grammar).to parse('OR(1, 2, 3)') }
    it { expect(grammar).to parse('OR(1, 2, 3, 4, 5, 6)') }
    it { expect(grammar).to parse('OR(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)') }
  end

  context 'IF statements' do
    it { expect(grammar).to parse('IF(3, 2, 1)') }
    it { expect(grammar).to parse('IF(3 > 1, 2, 1)') }
    it { expect(grammar).to parse('IF((3 > 1) || (2 < 1), 2, 1)') }
    it { expect(grammar).to parse('IF(OR(1 > 3, 2 < 5), 3, 2)') }
  end

  context 'Nested IF statements' do
    it { expect(grammar).to parse('IF(3 > 2, IF(2 < 3, 1, 3), 5)') }
    it { expect(grammar).to parse('IF(3 > 2, IF(2 < 3, 1, 3), IF(5 > 1, 3, 9))') }
  end

  context 'MAX statements' do
    it { expect(grammar).to parse('MAX(3, 1, 2)') }
    it { expect(grammar).to parse('MAX(-1, 2*4, (3-1)*2, 5, 6)') }
    it { expect(grammar).to parse('MAX(1, var, 10)') }
  end

  context 'MIN statements' do
    it { expect(grammar).to parse('MIN(3, 1, 2)') }
    it { expect(grammar).to parse('MIN(-1, 2*4, (3-1)*2, 5, 6)') }
    it { expect(grammar).to parse('MIN(1, -var, 10)') }
  end

  context 'Quoted identifiers and strings' do
    it { expect(grammar).to parse("'Hello world' := 1; 'Hello world' + 2") }
    it { expect(grammar).to parse('IF(TRUE, "", "ERROR")') }
    it { expect(grammar).to parse('TEXTJOIN("", FALSE, "a""b", "c")') }
  end

  context 'Array literals' do
    it { expect(grammar).to parse('[1; 2; 3]') }
    it { expect(grammar).to parse('[1, 2, 3]') }
    it { expect(grammar).to parse('["name", "score"; "Ada", 98]') }

    it do
      expect(grammar).to parse(<<~KALC)
        [
          "name", "score";
          "Ada", 98;
          "Grace", 100
        ]
      KALC
    end

    it { expect(grammar).not_to parse('[1, 2; 3]') }
  end

  context 'Function definitions' do
    it do
      expect(grammar).to parse(<<~KALC)
        DEFINE ADD(x, y) {
          x +
          y
        }

        ADD(1, 2)
      KALC
    end
  end
end
