module Kalc
  class Transform < Parslet::Transform
    rule(:expressions => sequence(:expressions)) {
      Ast::Expressions.new(expressions)
    }

    rule(:expressions => simple(:expressions)) {
      Ast::Expressions.new([expressions])
    }
    
    rule(:number => simple(:number)) { 
      Ast::FloatingPointNumber.new(number) 
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

    rule(:assign => {:value => simple(:value), :identifier => simple(:identifier), :operator => simple(:operator)}) {
      Ast::Identifier.new(identifier, value)
    }

    rule(:paren_list => sequence(:paren_list)) {
      paren_list
    }

    rule(:paren_list => "()") {
      []
    }

    rule(:function_call => {:name => simple(:name),
         :variable_list => sequence(:variable_list)}) {
      Ast::FunctionCall.new(name, variable_list)
    }

    rule(:function_definition => {:name => simple(:name),
         :argument_list => sequence(:argument_list),
         :body => simple(:body)}) {
      Ast::FunctionDefinition.new(name, argument_list, body)
    }
  end
end
