class Kalc::Transform < Parslet::Transform
  rule(:number => simple(:number)) { Float(number) }
  
  rule(:left => simple(:left), :right => simple(:right), :operator => '&&') { left && right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '||') { left || right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '<=') { left <= right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '>=') { left >= right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '==') { left == right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '!=') { left != right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '-') { left - right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '+') { left + right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '*') { left * right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '/') { left / right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '%') { left % right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '<') { left < right }
  rule(:left => simple(:left), :right => simple(:right), :operator => '>') { left > right }

  rule(:condition => simple(:condition), :true => simple(:true_cond), :false => simple(:false_cond)) { 
    condition ? true_cond : false_cond
  }

  rule(:variable => simple(:variable)) {

  }

  rule(:assign => {:value => simple(:value), :identifier => simple(:identifier)}) {

  }

  rule(:function_definition => {:name => simple(:name),
       :argument_list => sequence(:argument_list)}) {
  }
end

