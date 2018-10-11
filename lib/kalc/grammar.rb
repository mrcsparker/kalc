# Started with https://github.com/postmodern/cparser code
# which is based on http://www.lysator.liu.se/c/ANSI-C-grammar-y.html
# and worked from there
#
# The second link really helped when it came to functions

class Kalc::Grammar < Parslet::Parser
  rule(:new_line) { match('[\n\r]').repeat(1) }

  rule(:space) { match('[ \t\v\n\f]') }
  rule(:spaces) { space.repeat(1) }
  rule(:space?) { space.maybe }
  rule(:spaces?) { space.repeat }

  rule(:digit) { match('[0-9]') }
  rule(:digits) { digit.repeat(1) }
  rule(:digits?) { digit.repeat }

  rule(:alpha) { match('[_a-zA-Z]') }

  rule(:new_line) { match('[\n\r]').repeat(1) }
  rule(:separator) { str(';') >> spaces? }

  def self.symbols(symbols)
    symbols.each do |name, symbol|
      rule(name) { str(symbol) >> spaces? }
    end
  end

  symbols left_paren: '(',
          right_paren: ')',
          left_brace: '{',
          right_brace: '}',
          comma: ',',
          colon: ':',
          question_mark: '?'

  def self.operators(operators = {})
    trailing_chars = Hash.new { |hash, symbol| hash[symbol] = [] }

    operators.each_value do |symbol|
      operators.each_value do |op|
        next unless op[0, symbol.length] == symbol

        char = op[symbol.length, 1]

        trailing_chars[symbol] << char unless char.nil? || char.empty?
      end
    end

    operators.each do |name, symbol|
      trailing = trailing_chars[symbol]

      if trailing.empty?
        rule(name) {str(symbol).as(:operator) >> spaces?}
      else
        pattern = "[#{Regexp.escape(trailing.join)}]"

        rule(name) do
          (str(symbol) >> match(pattern).absnt?).as(:operator) >> spaces?
        end
      end
    end
  end

  operators logical_and: '&&',
            string_and: 'and',
            logical_or: '||',
            string_or: 'or',
            less_equal: '<=',
            greater_equal: '>=',
            equal: '==',
            not_equal: '!=',

            assign: ':=',
            excel_equal: '=',

            subtract: '-',
            add: '+',
            multiply: '*',
            divide: '/',
            modulus: '%',
            power_of: '^',

            less: '<',
            greater: '>'

  rule(:true_keyword) do
    str('TRUE') >> spaces?
  end

  rule(:false_keyword) do
    str('FALSE') >> spaces?
  end

  rule(:boolean) do
    (true_keyword | false_keyword).as(:boolean)
  end

  rule(:string) do
    str('"') >>
      (
        str('\\') >> any | str('"').absnt? >> any
      ).repeat.as(:string) >> str('"')
  end

  rule(:exponent) do
    match('[eE]') >> match('[-+]').maybe >> digits
  end

  # We are using a really broad definition of what a number is.
  # Numbers can be 1, 1.0, 0.1, 1.0e4, +1.0E10, etc
  rule(:number) do
    (match('[+-]').maybe >>
      (str('.') >> digits >> exponent.maybe).as(:number) >> spaces?) |
      (match('[+-]').maybe >> digits >> (str('.') >> digits).maybe >> exponent.maybe).as(:number) >> spaces?
  end

  rule(:identifier) do
    (alpha >> (alpha | digit).repeat) >> spaces?
  end

  rule(:quoted_identifier) do
    str("'") >> (
      str('\\') >> any | str("'").absnt? >> any
    ).repeat(1) >> str("'") >> spaces?
  end

  rule(:argument) do
    identifier.as(:argument)
  end

  # Should look like 'Name'
  rule(:variable) do
    identifier | quoted_identifier
  end

  # Does not self-evaluate
  # Use to call function: FUNCTION_NAME(variable_list, ..)
  rule(:variable_list) do
    conditional_expression >> (comma >> conditional_expression).repeat
  end

  rule(:paren_variable_list) do
    (left_paren >> variable_list.repeat >> right_paren).as(:paren_list)
  end

  # Does not self-evaluate
  # Used to create function: DEF FUNCTION_NAME(argument_list, ..)
  rule(:argument_list) do
    argument >> (comma >> argument).repeat
  end

  rule(:paren_argument_list) do
    (left_paren >> argument_list.repeat >> right_paren).as(:paren_list)
  end

  # Atoms can self-evaluate
  # This where the grammar starts
  rule(:atom) do
    paren_expression.as(:paren_expression) | boolean | variable.as(:variable) | number | string
  end

  # (1 + 2)
  rule(:paren_expression) do
    left_paren >> conditional_expression >> right_paren
  end

  rule(:non_ops_expression) do
    (atom.as(:left) >>
      power_of >>
      atom.as(:right)).as(:non_ops) | atom
  end

  # IF(1, 2, 3)
  # AND(1, 2, ...)
  rule(:function_call_expression) do
    (identifier.as(:name) >> paren_variable_list.as(:variable_list)).as(:function_call) |
      (str('+') >> non_ops_expression).as(:positive) |
      (str('-') >> non_ops_expression).as(:negative) | non_ops_expression
  end

  # 1 + 2
  rule(:additive_expression) do
    multiplicative_expression.as(:left) >>
      ((add | subtract) >>
        multiplicative_expression.as(:right)).repeat.as(:ops)
  end

  # 1 * 2
  rule(:multiplicative_expression) do
    function_call_expression.as(:left) >>
      ((multiply | divide | modulus) >>
        function_call_expression.as(:right)).repeat.as(:ops)
  end

  # 1 < 2
  # 1 > 2
  # 1 <= 2
  # 1 >= 2
  rule(:relational_expression) do
    additive_expression.as(:left) >>
      ((less | greater | less_equal | greater_equal) >>
        relational_expression.as(:right)).repeat.as(:ops)
  end

  # 1 = 2
  rule(:equality_expression) do
    relational_expression.as(:left) >>
      ((excel_equal | equal | not_equal) >>
        equality_expression.as(:right)).repeat.as(:ops)
  end

  # 1 && 2
  rule(:logical_and_expression) do
    equality_expression.as(:left) >>
      ((logical_and | string_and) >>
        logical_and_expression.as(:right)).repeat.as(:ops)
  end

  # 1 || 2
  rule(:logical_or_expression) do
    logical_and_expression.as(:left) >>
      ((logical_or | string_or) >>
        logical_or_expression.as(:right)).repeat.as(:ops)
  end

  # 1 > 2 ? 3 : 4
  rule(:conditional_expression) do
    logical_or_expression.as(:condition) >>
      (question_mark >>
        conditional_expression.as(:true_cond) >>
        colon >>
        conditional_expression.as(:false_cond)).maybe
  end

  # 'a' = 1
  # We don't allow for nested assignments:
  # IF('a' = 1, 1, 2)
  rule(:assignment_expression) do
    (variable.as(:identifier) >>
      assign >>
      assignment_expression.as(:value)).as(:assign) |
      conditional_expression
  end

  rule(:expression) do
    assignment_expression
  end

  rule(:expressions) do
    expression >> (separator >> expressions).repeat
  end

  rule(:function_body) do
    expressions.as(:expressions)
  end

  rule(:function_definition_expression) do
    (str('DEFINE') >> spaces? >> identifier.as(:name) >>
      paren_argument_list.as(:argument_list) >>
      left_brace >> function_body.as(:body) >> right_brace).as(:function_definition) |
      expressions.as(:expressions)
  end

  rule(:function_definition_expressions) do
    function_definition_expression >> separator.maybe >> function_definition_expressions.repeat
  end

  rule(:commands) do
    function_definition_expressions | expressions
  end

  rule(:line) do
    commands.as(:commands)
  end

  rule(:lines) do
    line >> (new_line >> lines).repeat
  end

  root :lines
end
