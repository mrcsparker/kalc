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

  symbols :left_paren => '(',
          :right_paren => ')',
          :left_brace => '{',
          :right_brace => '}',
          :comma => ',',
          :colon => ':',
          :question_mark => '?'

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
            :string_and => 'and',
            :logical_or => '||',
            :string_or => 'or',
            :less_equal => '<=',
            :greater_equal => '>=',
            :equal => '==',
            :not_equal => '!=',

            :assign => ':=',
            :excel_equal => '=',

            :subtract => '-',
            :add => '+',
            :multiply => '*',
            :divide => '/',
            :modulus => '%',
            :power_of => '^',

            :less => '<',
            :greater => '>'

  rule(:true_keyword) {
    str('TRUE') >> spaces?
  }

  rule(:false_keyword) {
    str('FALSE') >> spaces?
  }

  rule(:boolean) {
    (true_keyword | false_keyword).as(:boolean)
  }

  rule(:string) {
    str('"') >> 
    (
      str('\\') >> any |
      str('"').absnt? >> any
    ).repeat.as(:string) >> 
    str('"')
  }

  rule(:exponent) {
    match('[eE]') >> match('[-+]').maybe >> digits
  }

  # We are using a really broad definition of what a number is.
  # Numbers can be 1, 1.0, 0.1, 1.0e4, +1.0E10, etc
  rule(:number) {
    (match('[+-]').maybe >> 
      (str('.') >> digits >> exponent.maybe).as(:number) >> spaces?) |
    (match('[+-]').maybe >> 
     digits >> (str('.') >> digits).maybe >> exponent.maybe).as(:number) >> spaces?
  }

  rule(:identifier) {
    (alpha >> (alpha | digit).repeat) >> spaces?
  }

  rule(:quoted_identifier) {
    str("'") >> 
    (
      str('\\') >> any  | str("'").absnt? >> any
    ).repeat(1) >>
    str("'") >> spaces?
  }

  rule(:argument) {
    identifier.as(:argument)
  }

  # Should look like 'Name'
  rule(:variable) {
    #identifier | (str("'") >> spaces? >> identifier.repeat >> str("'")) >> spaces?
    identifier | quoted_identifier
  }

  # Does not self-evaluate
  # Use to call function: FUNCTION_NAME(variable_list, ..)
  rule(:variable_list) {
    conditional_expression >> (comma >> conditional_expression).repeat
  }

  rule(:paren_variable_list) {
    (left_paren >> variable_list.repeat >> right_paren).as(:paren_list)
  }

  # Does not self-evaluate
  # Used to create function: DEF FUNCTION_NAME(argument_list, ..)
  rule(:argument_list) {
    argument >> (comma >> argument).repeat
  }

  rule(:paren_argument_list) {
    (left_paren >> argument_list.repeat >> right_paren).as(:paren_list)
  }

  # Atoms can self-evaluate
  # This where the grammar starts
  rule(:atom) {
    paren_expression.as(:paren_expression) | boolean | variable.as(:variable) | number | string
  }

  # (1 + 2)
  rule(:paren_expression) {
    left_paren >> conditional_expression >> right_paren
  }

  rule(:non_ops_expression) {
    (atom.as(:left) >> 
      power_of >>
      atom.as(:right)).as(:non_ops) | atom
  }

  # IF(1, 2, 3)
  # AND(1, 2, ...)
  rule(:function_call_expression) {
    (identifier.as(:name) >> paren_variable_list.as(:variable_list)).as(:function_call) |
    (str('+') >> non_ops_expression).as(:positive) |
    (str('-') >> non_ops_expression).as(:negative) | non_ops_expression
  }

  # 1 + 2
  rule(:additive_expression) {
    multiplicative_expression.as(:left) >> 
      ((add | subtract) >> 
        multiplicative_expression.as(:right)).repeat.as(:ops)
  }

  # 1 * 2
  rule(:multiplicative_expression) {
    function_call_expression.as(:left) >> 
      ((multiply | divide | modulus) >> 
        function_call_expression.as(:right)).repeat.as(:ops)
  }

  # 1 < 2
  # 1 > 2
  # 1 <= 2
  # 1 >= 2
  rule(:relational_expression) {
    additive_expression.as(:left) >> 
      ((less | greater | less_equal | greater_equal) >>
        relational_expression.as(:right)).repeat.as(:ops)
  }

  # 1 = 2
  rule(:equality_expression) {
    relational_expression.as(:left) >>
      ((excel_equal | equal | not_equal) >>
        equality_expression.as(:right)).repeat.as(:ops)
  }

  # 1 && 2
  rule(:logical_and_expression) {
    equality_expression.as(:left) >>
      ((logical_and | string_and) >>
        logical_and_expression.as(:right)).repeat.as(:ops)
  }

  # 1 || 2
  rule(:logical_or_expression) {
    logical_and_expression.as(:left) >>
      ((logical_or | string_or) >>
        logical_or_expression.as(:right)).repeat.as(:ops)
  }

  # 1 > 2 ? 3 : 4
  rule(:conditional_expression) {
    logical_or_expression.as(:condition) >> 
      (question_mark >> 
        conditional_expression.as(:true_cond) >> 
        colon >> 
        conditional_expression.as(:false_cond)).maybe
  }

  # 'a' = 1
  # We don't allow for nested assignments:
  # IF('a' = 1, 1, 2)
  rule(:assignment_expression) {
    (variable.as(:identifier) >> 
      assign >> 
      assignment_expression.as(:value)).as(:assign) |
    conditional_expression
  }

  rule(:expression) {
    assignment_expression
  }

  rule(:expressions) {
    expression >> (separator >> expressions).repeat
  }

  rule(:function_body) {
    expressions.as(:expressions)
  }

  rule(:function_definition_expression) {
    (str('DEFINE') >> spaces? >> identifier.as(:name) >>
         paren_argument_list.as(:argument_list) >>
         left_brace >> function_body.as(:body) >> right_brace).as(:function_definition) |
    expressions.as(:expressions)
  }

  rule(:function_definition_expressions) {
    function_definition_expression >> separator.maybe >> function_definition_expressions.repeat
  }

  rule(:commands) {
    function_definition_expressions | expressions
  }

  rule(:line) {
    commands.as(:commands)
  }

  rule(:lines) {
    line >> (new_line >> lines).repeat
  }

  root :lines
end

