module Kalc

  class Transform < Parslet::Transform
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

    rule(:assign => {:value => simple(:value), :identifier => simple(:identifier)}) {
      Ast::Identifier.new(identifier, value)
    }

    rule(:function_call => {:name => simple(:name),
         :argument_list => sequence(:argument_list)}) {
      Ast::FunctionCall.new(name, argument_list)
    }
  end
end
