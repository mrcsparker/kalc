require 'spec_helper'

describe Kalc::Interpreter do
  before(:each) do
    @grammar = Kalc::Grammar.new
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
    expect(evaluate('a := 1')).to eq(1)
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

  it { expect(evaluate('((75.0)*(25.0))+((125.0)*(25.0))+((150.0)*(25.0))+((250.0)*(25.0))')).to eq(15_000) }

  it { expect(evaluate('(((40.0)/1000*(4380.0)*(200.0))-((40.0)/1000*(4380.0)*((((75.0)*(25.0))+((125.0)*(25.0))+((150.0)*(25.0))+((250.0)*(25.0)))/(10.0)/(40.0)/(0.8))))*(0.05)')).to eq(1341.375) }

  context 'Negative numbers' do
    it { expect(evaluate('-2')).to eq(-2) }
    it { expect(evaluate('-1000')).to eq(-1000) }
    it { expect(evaluate('-1000.0001')).to eq(-1000.0001) }
    it { expect(evaluate('1 + -1')).to eq(0) }
    it { expect(evaluate('1 + -10')).to eq(-9) }
  end

  context 'Positive numbers' do
    it { expect(evaluate('1 + +1')).to eq(2) }
    it { expect(evaluate('1 + +1 - 1')).to eq(1) }
    it { expect(evaluate('+10000.0001')).to eq(10_000.0001) }
  end

  context 'Boolean value' do
    it { expect(evaluate('TRUE')).to eq(true) }
    it { expect(evaluate('FALSE')).to eq(false) }
    it { expect(evaluate('FALSE || TRUE')).to eq(true) }
    it { expect(evaluate('FALSE && TRUE')).to eq(false) }
    it { expect(evaluate('flag := FALSE; flag')).to eq(false) }

    it 'short-circuits infix logical operators' do
      expect(evaluate('FALSE && SYSTEM("echo nope")')).to eq(false)
      expect(evaluate('TRUE || SYSTEM("echo nope")')).to eq(true)
      expect(evaluate('FALSE and SYSTEM("echo nope")')).to eq(false)
      expect(evaluate('TRUE or SYSTEM("echo nope")')).to eq(true)
    end
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

  context 'Array literals' do
    it 'evaluates vertical lists' do
      expect(evaluate('[1; 2; 3]').rows).to eq([[1], [2], [3]])
    end

    it 'evaluates rectangular tables' do
      expect(evaluate('["name", "score"; "Ada", 98]').rows).to eq([%w[name score], ['Ada', 98]])
    end

    it 'recalculates array formulas lazily' do
      expect(evaluate(<<~KALC)).to eq(21)
        price := 1
        items := [price; price + 1]
        price := 10
        SUM(items)
      KALC
    end
  end

  context 'Ternary' do
    it { expect(evaluate('1 > 2 ? 1 : 2')).to eq(2) }
  end

  context 'Exponents' do
    it { expect(evaluate('1.23e+10')).to eq(12_300_000_000.0) }
    it { expect(evaluate('1.23e-10')).to eq(1.23e-10) }
  end

  context 'Numbers starting with a decimal point' do
    it { expect(evaluate('0.4')).to eq(0.4) }
    it { expect(evaluate('.4')).to eq(0.4) }
  end

  context 'Min and Max Functions' do
    it { expect(evaluate('MAX(3, 1, 2)')).to eq(3) }
    it { expect(evaluate('MAX(-1, 2*4, (3-1)*2, 5, 6)')).to eq(8) }
    it { expect(evaluate('MAX(0/0, 2)').to_s).to eq('NaN') }
    it { expect(evaluate('MAX(1/0, 3)').to_s).to eq('Infinity') }
    it { expect(evaluate('MIN(3, 1, 2)')).to eq(1) }
    it { expect(evaluate('MIN(-1, 2*4, (3-1)*2, 5, 6)')).to eq(-1) }
    it { expect(evaluate('MIN(0/0, 2)').to_s).to eq('NaN') }
    it { expect(evaluate('MIN(-1/0, 3)').to_s).to eq('-Infinity') }
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
    it { expect(evaluate('FLOOR(0/0)').to_s).to eq('NaN') }
    it { expect(evaluate('FLOOR(1/0)').to_s).to eq('Infinity') }
    it { expect(evaluate('CEILING(3)')).to eq(3) }
    it { expect(evaluate('CEILING(3.8)')).to eq(4) }
    it { expect(evaluate('CEILING(3.8)')).to eq(4) }
    it { expect(evaluate('CEILING(-3.2)')).to eq(-3) }
    it { expect(evaluate('CEILING(0/0)').to_s).to eq('NaN') }
    it { expect(evaluate('CEILING(1/0)').to_s).to eq('Infinity') }

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

  context 'Excel compatibility functions' do
    it { expect(evaluate('AVERAGE(2, 4, 6)')).to eq(4) }
    it { expect(evaluate('COUNT(1, "x", TRUE, 2)')).to eq(2) }
    it { expect(evaluate('COUNTIF([1; 2; 3; 4], ">=3")')).to eq(2) }
    it { expect(evaluate('COUNTIF(["001"; "002"], "001")')).to eq(1) }
    it { expect(evaluate('COUNTA(1, "", FALSE, "x")')).to eq(4) }
    it { expect(evaluate('MOD(10, 3)')).to eq(1) }
    it { expect(evaluate('QUOTIENT(-10, 3)')).to eq(-3) }
    it { expect(evaluate('POWER(2, 5)')).to eq(32) }
    it { expect(evaluate('INT(-3.1)')).to eq(-4) }
    it { expect(evaluate('ROUNDUP(3.141, 2)')).to eq(3.15) }
    it { expect(evaluate('ROUNDDOWN(-3.149, 2)')).to eq(-3.14) }
    it { expect(evaluate('MROUND(10, 4)')).to eq(12) }
    it { expect(evaluate('SIGN(-10)')).to eq(-1) }
    it { expect(evaluate('SIGN(0)')).to eq(0) }
    it { expect(evaluate('PI()')).to eq(Math::PI) }
    it { expect(evaluate('FIND("c", "abc")')).to eq(3) }
    it { expect(evaluate('SEARCH("C", "abc")')).to eq(3) }
    it { expect(evaluate('SUBSTITUTE("banana", "a", "o", 2)')).to eq('banona') }
    it { expect(evaluate('SUMIF([10; 20; 30; 40], ">=30")')).to eq(70) }
    it { expect(evaluate('SUMIF(["001"; "002"], "001", [5; 10])')).to eq(5) }
    it { expect(evaluate('TEXTJOIN("-", TRUE, "a", "", "b")')).to eq('a-b') }
    it { expect(evaluate('IFS(1 > 2, "no", 2 > 1, "yes")')).to eq('yes') }
    it { expect(evaluate('CHOOSE(2, "alpha", "beta", "gamma")')).to eq('beta') }
    it { expect(evaluate('SWITCH(2, 1, "one", 2, "two", "other")')).to eq('two') }

    it 'returns an integer in the requested RANDBETWEEN range' do
      value = evaluate('RANDBETWEEN(3, 5)')

      expect(value).to be_between(3, 5)
      expect(value % 1).to eq(0)
    end
  end

  context 'Array functions' do
    it { expect(evaluate('SUM([10; 20; 30])')).to eq(60) }
    it { expect(evaluate('AVERAGE([1, 2; 3, 4])')).to eq(2.5) }
    it { expect(evaluate('COUNT([1; "x"; TRUE; 2])')).to eq(2) }
    it { expect(evaluate('COUNTA([1; ""; FALSE; "x"])')).to eq(4) }
    it { expect(evaluate('MATCH("Grace", ["Ada"; "Grace"; "Katherine"])')).to eq(2) }
    it { expect(evaluate('MATCH(25, [10; 20; 30], 1)')).to eq(2) }
    it { expect(evaluate('MATCH(15, [10; 20; 30], -1)')).to eq(2) }
    it { expect(evaluate('TEXTJOIN("-", TRUE, ["a"; ""; "b"])')).to eq('a-b') }
    it { expect(evaluate('CONCATENATE(["Ada"; " "; "Lovelace"])')).to eq('Ada Lovelace') }
    it { expect(evaluate('ROWS(["name", "score"; "Ada", 98])')).to eq(2) }
    it { expect(evaluate('COLUMNS([1, 2, 3])')).to eq(3) }
    it { expect(evaluate('INDEX([10; 20; 30], 2)')).to eq(20) }
    it { expect(evaluate('INDEX(["name", "score"; "Ada", 98], 2, 2)')).to eq(98) }
    it { expect(evaluate('TRANSPOSE([1; 2; 3])').rows).to eq([[1, 2, 3]]) }
    it { expect(evaluate('UNIQUE([1; 1; 2; 2; 3])').rows).to eq([[1], [2], [3]]) }
    it { expect(evaluate('SORT([3; 1; 2])').rows).to eq([[1], [2], [3]]) }
    it { expect(evaluate('FILTER([10; 20; 30], [FALSE; TRUE; TRUE])').rows).to eq([[20], [30]]) }
    it { expect(evaluate('SEQUENCE(2, 3, 1, 1)').rows).to eq([[1, 2, 3], [4, 5, 6]]) }

    it 'looks up a scalar from a vector' do
      expect(evaluate('XLOOKUP("Grace", ["Ada"; "Grace"; "Katherine"], [98; 100; 99])')).to eq(100)
    end

    it 'supports approximate xlookup matches' do
      expect(evaluate('XLOOKUP(15, [10; 20; 30], ["low"; "mid"; "high"], "missing", 1)')).to eq('mid')
      expect(evaluate('XLOOKUP(15, [10; 20; 30], ["low"; "mid"; "high"], "missing", -1)')).to eq('low')
    end

    it 'keeps xlookup configuration errors visible even with if_not_found' do
      expect { evaluate('XLOOKUP("Grace", ["Ada"; "Grace"], [1], "missing")') }
        .to raise_error(ArgumentError, /same length/)

      expect { evaluate('XLOOKUP(1, [1; 2], [10; 20], "missing", 99)') }
        .to raise_error(ArgumentError, /match mode/)
    end

    it 'looks up a row from a table' do
      result = evaluate('XLOOKUP("Grace", ["Ada"; "Grace"], ["engineer", 98; "scientist", 100])')

      expect(result.rows).to eq([['scientist', 100]])
    end

    it 'rejects mismatched sumif shapes' do
      expect { evaluate('SUMIF(["a", "x"; "x", "a"], "x", [1; 2; 3; 4])') }
        .to raise_error(ArgumentError, /same shape/)
    end

    it 'raises clearly when unique has no results' do
      expect { evaluate('UNIQUE([1; 1], FALSE, TRUE)') }
        .to raise_error(ArgumentError, /UNIQUE returned no results/)
    end
  end

  context 'Lazy formulas' do
    it 'detects circular references' do
      expect { evaluate('a := a + 1') }
        .to raise_error(Kalc::CircularReferenceError, /Circular reference detected for a/)
    end
  end

  context 'Function calls' do
    it 'evaluates arguments in the caller scope' do
      expect(evaluate(<<~KALC)).to eq(10)
        x := 10
        DEFINE IDENTITY_PAIR(x, y) {
          y
        }
        IDENTITY_PAIR(1, x)
      KALC
    end

    it 'keeps builtin value errors visible' do
      expect { evaluate('RIGHT("abc", "x")') }
        .to raise_error(ArgumentError, /invalid value for Integer/)
    end
  end

  context 'Unary operations' do
    it 'does not evaluate operands twice when they fail' do
      error = nil

      expect do
        evaluate('-(PUTS("x"))')
      rescue StandardError => e
        error = e
      end.to output("x\n").to_stdout

      expect(error).to be_a(NoMethodError)
    end
  end

  # https://github.com/mrcsparker/kalc/issues/9
  context 'empty strings' do
    it { expect(evaluate('""')).to eq('') }
    it { expect(evaluate('var1 := 1; var2 := 2; IF(var1=var2,"","ERROR")')).to eq('ERROR') }
    it { expect(evaluate('var1 := 1; var2 := 1; IF(var1=var2,"","ERROR")')).to eq('') }
  end

  private

  def evaluate(expression)
    Kalc::Interpreter.new.run(@grammar.parse(expression))
  end
end
