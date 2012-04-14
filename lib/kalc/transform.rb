module Kalc
  class Transform < Parslet::Transform

    rule(:condition => subtree(:condition)) { 
      condition 
    }

    rule(:left => subtree(:left), :ops => []) { 
      left 
    }

    rule(:right => subtree(:right), :ops => []) { 
      right 
    }

    rule(:left => subtree(:left), :non_ops => []) { 
      left 
    }

    rule(:right => subtree(:right), :non_ops => []) { 
      right 
    }

    rule(:commands => sequence(:commands)) {
      Ast::Commands.new(commands)
    }

    rule(:commands => simple(:commands)) {
      Ast::Commands.new([commands])
    }

    rule(:negative => simple(:negative)) {
      Ast::Negative.new(negative)
    }

    rule(:positive => simple(:positive)) {
      Ast::Positive.new(positive)
    }

    rule(:expressions => sequence(:expressions)) {
      Ast::Expressions.new(expressions)
    }

    rule(:expressions => simple(:expressions)) {
      Ast::Expressions.new([expressions])
    }

    rule(:string => simple(:string)) {
      Ast::StringValue.new(string)
    }

    rule(:boolean => simple(:boolean)) {
      Ast::BooleanValue.new(boolean)
    }

    rule(:number => simple(:number)) { 
      Ast::FloatingPointNumber.new(number) 
    }

    rule(:non_ops => subtree(:non_ops)) {
      Ast::NonOps.new(non_ops)
    }

    rule(:left => simple(:left), :ops => subtree(:ops)) {
      Ast::Ops.new(left, ops)
    }

    rule(:left => simple(:left), :right => simple(:right), :operator => simple(:operator)) { 
      Ast::Arithmetic.new(left, right, operator)
    }

    rule(:condition => simple(:condition), :true => simple(:true_cond), :false => simple(:false_cond)) { 
      Ast::Conditional.new(condition, true_cond, false_cond)
    }

    rule(:variable => simple(:variable)) {
      Ast::Variable.new(variable)
    }

    rule(:identifier => simple(:identifier)) {
      identifier
    }

    rule(:assign => {:value => simple(:value), :identifier => simple(:identifier), :operator => simple(:operator)}) {
      Ast::Identifier.new(identifier, value)
    }

    rule(:paren_list => sequence(:paren_list)) {
      paren_list
    }

    rule(:paren_list => "()") {
      []
    }

    rule(:paren_expression => simple(:paren_expression)) {
      Ast::ParenExpression.new(paren_expression)
    }

    rule(:function_call => {:name => simple(:name),
         :variable_list => sequence(:variable_list)}) {
      Ast::FunctionCall.new(name, variable_list)
    }

    rule(:argument => simple(:argument)) {
      Ast::Identifier.new(argument, argument)
    }

    rule(:function_definition => {:name => simple(:name),
         :argument_list => sequence(:argument_list),
         :body => simple(:body)}) {
      Ast::FunctionDefinition.new(name, argument_list, body)
    }
  end
end
