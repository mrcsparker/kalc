require 'spec_helper'

describe Kalc::Interpreter do
  before(:each) do
    @grammar = Kalc::Grammar.new
    @transform = Kalc::Transform.new
  end

  it { expect(evaluate('2 + 2')).to eq(4) }
  it { expect(evaluate('1 + 1')).to eq(2.0) }
  it { expect(evaluate('4 + 1')).to eq(5) }
  it { expect(evaluate('5 + 5')).to eq(10) }

  it { expect(evaluate('5 / 5')).to eq(1) }

  it { expect(evaluate('5 / 4 / 2')).to eq(0.625) }
  it { expect(evaluate('5/4/2')).to eq(0.625) }

  it { expect(evaluate('6 * 2 / 3')).to eq(4) }

  it { expect(evaluate('10 > 9')).to eq(true) }
  it { expect(evaluate('10 < 9')).to eq(false) }

  it { expect(evaluate('10 + 19 + 11 * 3')).to eq(62) }

  it { expect(evaluate('10 >= 10')).to eq(true) }

  it { expect(evaluate('ABS(-1 + -2)')).to eq(3) }

  it 'should be able to load variables' do
    expect(evaluate('a := 1; 1 + a')).to eq(2)
    expect(evaluate('a := 1; b := 2; 1 + b')).to eq(3)
  end

  it 'should be able to load quoted variables' do
    expect(evaluate("'Item (a)' := 1; 1 + 'Item (a)'")).to eq(2)
    expect(evaluate("'a' := 1; 'b[a]' := 2 + 'a'; 1 + 'b[a]'")).to eq(4)
  end

  it 'should be able to load single quoted variables' do
    expect(evaluate("'a' := 1; 1 + 'a'")).to eq(2)
    expect(evaluate("'a' := 1; 'b' := 2; 'b' + 'a'")).to eq(3)

    expect(evaluate("'a b' := 1; 'a b' + 1")).to eq(2)
  end

  it { expect(evaluate('((75.0)*(25.0))+((125.0)*(25.0))+((150.0)*(25.0))+((250.0)*(25.0))')).to eq(15000) }

  it { expect(evaluate('(((40.0)/1000*(4380.0)*(200.0))-((40.0)/1000*(4380.0)*((((75.0)*(25.0))+((125.0)*(25.0))+((150.0)*(25.0))+((250.0)*(25.0)))/(10.0)/(40.0)/(0.8))))*(0.05)')).to eq(1341.375) }

  context 'Negative numbers' do
    it { expect(evaluate('-2')).to eq(-2) }
    it { expect(evaluate('-1000')).to eq(-1000) }
    it { expect(evaluate('-1000.0001')).to eq(-1000.0001) }
    it { expect(evaluate('1 + -1')).to eq(0 )}
    it { expect(evaluate('1 + -10')).to eq(-9) }
  end

  context 'Positive numbers' do
    it { expect(evaluate('1 + +1')).to eq(2) }
    it { expect(evaluate('1 + +1 - 1')).to eq(1) }
    it { expect(evaluate('+10000.0001')).to eq(10000.0001) }
  end

  context 'Boolean value' do
    it { expect(evaluate('TRUE')).to eq(true) }
    it { expect(evaluate('FALSE')).to eq(false) }
    it { expect(evaluate('FALSE || TRUE')).to eq(true) }
    it { expect(evaluate('FALSE && TRUE')).to  eq(false) }
  end

  context 'Decimal numbers' do
    it { expect(evaluate('1.01')).to eq(1.01) }
    it { expect(evaluate('1.01 + 0.02')).to eq(1.03) }
    it { expect(evaluate('1.01 - 0.01')).to eq(1) }
    it { expect(evaluate('1.1 + 1.1')).to eq(2.2) }
    it { expect(evaluate('1.2 - 1.0')).to eq(0.2) }
    it { expect(evaluate('1.01 = 1.01')).to eq(true) }
    it { expect(evaluate('1.01 = 1.02')).to eq(false) }
  end

  context 'Ternary' do
    it { expect(evaluate('1 > 2 ? 1 : 2')).to eq(2) }
  end

  context 'Exponents' do
    it { expect(evaluate('1.23e+10')).to eq(12300000000.0) }
    it { expect(evaluate('1.23e-10')).to eq(1.23e-10) }
  end

  context 'Numbers starting with a decimal point' do
    it { expect(evaluate('0.4')).to eq(0.4) }
    it { expect(evaluate('.4')).to eq(0.4) }
  end

  context 'Min and Max Functions' do
    it { expect(evaluate('MAX(3, 1, 2)')).to eq(3) }
    it { expect(evaluate('MAX(-1, 2*4, (3-1)*2, 5, 6)')).to eq(8) }
    it { expect(evaluate('MAX(0/0, 2)').to_s).to eq("NaN") }
    it { expect(evaluate('MAX(1/0, 3)').to_s).to eq("Infinity") }
    it { expect(evaluate('MIN(3, 1, 2)')).to eq(1) }
    it { expect(evaluate('MIN(-1, 2*4, (3-1)*2, 5, 6)')).to eq(-1) }
    it { expect(evaluate('MIN(0/0, 2)').to_s).to eq("NaN") }
    it { expect(evaluate('MIN(-1/0, 3)').to_s).to eq("-Infinity") }
    context 'having variables' do
      it { expect(evaluate('var := 15; MAX(1, var, 10)')).to eq(15) }
      it { expect(evaluate('var := 15; MIN(1, var, -10)')).to eq(-10) }
    end
  end

  context 'Ceil and Floor functions' do
    it { expect(evaluate('FLOOR(3.4)')).to eq(3) }
    it { expect(evaluate('FLOOR(3.8)')).to eq(3) }
    it { expect(evaluate('FLOOR(-3.4)')).to eq(-4) }
    it { expect(evaluate('FLOOR(3)')).to eq(3) }
    it { expect(evaluate('FLOOR(0/0)').to_s).to eq("NaN") }
    it { expect(evaluate('FLOOR(1/0)').to_s).to eq("Infinity") }
    it { expect(evaluate('CEILING(3)')).to eq(3) }
    it { expect(evaluate('CEILING(3.8)')).to eq(4) }
    it { expect(evaluate('CEILING(3.8)')).to eq(4) }
    it { expect(evaluate('CEILING(-3.2)')).to eq(-3) }
    it { expect(evaluate('CEILING(0/0)').to_s).to eq("NaN") }
    it { expect(evaluate('CEILING(1/0)').to_s).to eq("Infinity") }

    context 'having variables' do
      it { expect(evaluate('var := 2.456; FLOOR(var)')).to eq(2) }
      it { expect(evaluate('var := 2.444; CEILING(var)')).to eq(3) }
    end
  end

  context 'Round function' do
    it { expect(evaluate('ROUND(3.256,2)')).to eq(3.26) }
    it { expect(evaluate('ROUND(3.2,2)')).to eq(3.20) }
    it { expect(evaluate('ROUND(233.256,-2)')).to eq(200) }
  end

  # https://github.com/mrcsparker/kalc/issues/9
  # https://github.com/kschiess/parslet/issues/126
  context 'empty strings' do
    it { expect(evaluate('""')).to eq('') }
    it { expect(evaluate('var1 := 1; var2 := 2; IF(var1=var2,"","ERROR")')).to eq('ERROR') }
    it { expect(evaluate('var1 := 1; var2 := 1; IF(var1=var2,"","ERROR")')).to eq('') }
  end

  private
  def evaluate(expression)
    g = @grammar.parse(expression)
    ast = @transform.apply(g)
    Kalc::Interpreter.new.run(ast)
  end
end
