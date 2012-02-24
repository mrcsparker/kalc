# Started with https://github.com/postmodern/cparser code
# and worked from there

class Kalc::Grammar < Parslet::Parser

  rule(:new_line) { match('[\n\r]').repeat(1) }

  rule(:space) { match('[ \t\v\n\f]') }
  rule(:spaces) { space.repeat(1) }
  rule(:space?) { space.maybe }
  rule(:spaces?) { space.repeat }

  rule(:digit) { match('[0-9]') }
  rule(:digits) { digit.repeat(1) }
  rule(:digits?) { digit.repeat }

  rule(:alpha) { match('[a-zA-Z]') }

  def self.symbols(symbols) 
    symbols.each do |name, symbol|
      rule(name) { str(symbol) >> spaces? }
    end
  end

  symbols :left_paren => '(',
          :right_paren => ')',
          :comma => ',',
          :colon => ':',
          :semicolon => ';'

  def self.operators(operators={})
    trailing_chars = Hash.new { |hash,symbol| hash[symbol] = [] }

    operators.each_value do |symbol|
      operators.each_value do |op|
        if op[0,symbol.length] == symbol
          char = op[symbol.length,1]

          unless (char.nil? || char.empty?)
            trailing_chars[symbol] << char
          end
        end
      end
    end

    operators.each do |name,symbol|
      trailing = trailing_chars[symbol]

      if trailing.empty?
        rule(name) { str(symbol).as(:operator) >> spaces? }
      else
        pattern = "[#{Regexp.escape(trailing.join)}]"

        rule(name) {
          (str(symbol) >> match(pattern).absnt?).as(:operator) >> spaces?
        }
      end
    end
  end

  operators :logical_and => '&&',
            :logical_or => '||',
            :less_equal => '<=',
            :greater_equal => '>=',
            :equal => '==',
            :not_equal => '!=',

            :assign => '=',
            :question_mark => '?',

            :subtract => '-',
            :add => '+',
            :multiply => '*',
            :divide => '/',
            :modulus => '%',

            :less => '<',
            :greater => '>'

  rule(:and_keyword) { str('AND') }
  rule(:or_keyword) { str('OR') }
  rule(:if_keyword) { str('IF') }

  rule(:number) {
    (digits >> (str('.') >> digits).maybe).as(:number)
  }

  rule(:identifier) {
    (alpha >> (alpha | digit).repeat) >> spaces?
  }

  # Should look like 'Name'
  rule(:variable) {
    (str("'") >> identifier >> str("'")) >> spaces?
  }

  rule(:block) {
    left_paren >> expression >> right_paren
  }

  rule(:primary_expression) {
    variable.as(:variable) | block | number >> spaces?
  }

  rule(:argument_expression_list) {
    expression >> (comma >> expression).repeat(0,1)
  }

  rule(:argument_expression_block_list) {
    (left_paren >> argument_expression_list.repeat >> right_paren).as(:block_list)
  }

  rule(:multiplicative_expression) {
    primary_expression.as(:left) >> (multiply | divide | modulus) >> multiplicative_expression.as(:right) |
    primary_expression
  }

  rule(:additive_expression) {
    multiplicative_expression.as(:left) >> (add | subtract) >> additive_expression.as(:right) |
    multiplicative_expression
  }

  rule(:relational_expression) {
    additive_expression.as(:left) >> 
    (less | greater | less_equal | greater_equal) >>
    relational_expression.as(:right) | additive_expression
  }

  rule(:equality_expression) {
    relational_expression.as(:left) >>
    (equal | not_equal) >>
    equality_expression.as(:right) | relational_expression
  }

  rule(:logical_and_expression) {
    equality_expression.as(:left) >>
    logical_and >>
    logical_and_expression.as(:right) | equality_expression
  }

  rule(:logical_or_expression) {
    logical_and_expression.as(:left) >>
    logical_or >>
    logical_or_expression.as(:right) | logical_and_expression
  }

  rule(:conditional_expression) {
    logical_or_expression.as(:condition) >> question_mark >>
    expression.as(:true) >> colon >>
    expression.as(:false) | logical_or_expression
  }

  rule(:function_call) {
    (identifier.as(:name) >> argument_expression_block_list.as(:argument_list)).as(:function_call) | conditional_expression
  }

  rule(:assignment_expression) {
    (variable.as(:identifier) >>
      assign >> 
      function_call.as(:value)).as(:assign) | function_call
  }

  # Start here
  rule(:expression) {
    assignment_expression | additive_expression | variable | block
  }

  root :expression
end

