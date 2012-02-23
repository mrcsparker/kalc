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
end

