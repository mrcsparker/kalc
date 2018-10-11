module Kalc
  class Transform < Parslet::Transform
    rule(condition: subtree(:condition)) do
      condition
    end

    rule(right: subtree(:right), ops: []) do
      right
    end

    rule(left: subtree(:left), non_ops: []) do
      left
    end

    rule(right: subtree(:right), non_ops: []) do
      right
    end

    rule(commands: sequence(:commands)) do
      Ast::Commands.new(commands)
    end

    rule(commands: simple(:commands)) do
      Ast::Commands.new([commands])
    end

    rule(negative: simple(:negative)) do
      Ast::Negative.new(negative)
    end

    rule(positive: simple(:positive)) do
      Ast::Positive.new(positive)
    end

    rule(expressions: sequence(:expressions)) do
      Ast::Expressions.new(expressions)
    end

    rule(expressions: simple(:expressions)) do
      Ast::Expressions.new([expressions])
    end

    rule(string: simple(:string)) do
      Ast::StringValue.new(string)
    end

    rule(string: sequence(:string)) do
      string = '' if string.nil?
      Ast::StringValue.new(string)
    end

    rule(boolean: simple(:boolean)) do
      Ast::BooleanValue.new(boolean)
    end

    rule(number: simple(:number)) do
      Ast::BigDecimalNumber.new(number)
    end

    rule(non_ops: subtree(:non_ops)) do
      Ast::NonOps.new(non_ops)
    end

    rule(left: simple(:left), ops: subtree(:ops)) do
      ops.empty? ? left : Ast::Ops.new(left, ops)
    end

    rule(left: simple(:left), right: simple(:right), operator: simple(:operator)) do
      Ast::Arithmetic.new(left, right, operator)
    end

    rule(condition: simple(:condition), true_cond: simple(:true_cond), false_cond: simple(:false_cond)) do
      Ast::Conditional.new(condition, true_cond, false_cond)
    end

    rule(variable: simple(:variable)) do
      Ast::Variable.new(variable)
    end

    rule(identifier: simple(:identifier)) do
      identifier
    end

    rule(assign: { value: simple(:value), identifier: simple(:identifier), operator: simple(:operator) }) do
      Ast::Identifier.new(identifier, value)
    end

    rule(paren_list: sequence(:paren_list)) do
      paren_list
    end

    rule(paren_list: '()') do
      []
    end

    rule(paren_expression: simple(:paren_expression)) do
      Ast::ParenExpression.new(paren_expression)
    end

    rule(function_call: { name: simple(:name),
                          variable_list: sequence(:variable_list) }) do
      Ast::FunctionCall.new(name, variable_list)
    end

    rule(argument: simple(:argument)) do
      Ast::Identifier.new(argument, argument)
    end

    rule(function_definition: { name: simple(:name),
                                argument_list: sequence(:argument_list),
                                body: simple(:body) }) do
      Ast::FunctionDefinition.new(name, argument_list, body)
    end
  end
end
