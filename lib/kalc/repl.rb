require 'readline'
require 'pp'

module Kalc
  class Repl
    def run

      puts heading

      puts "= Loading grammar"
      @grammar = Kalc::Grammar.new

      puts "= Loading transform"
      @transform = Kalc::Transform.new

      puts "= Loading interpreter"
      @interpreter = Kalc::Interpreter.new

      puts "You are ready to go.  Have fun!"
      puts ""

      ast = nil

      begin
        while input = Readline.readline("kalc-#{Kalc::VERSION} > ", true)
          begin
            case
            when (input == 'quit' || input == 'exit')
              break
            when input == "functions"
              puts @interpreter.env.functions.map { |f| f.first }.join(", ")
            when input == 'variables'
              puts @interpreter.env.variables.map { |v| "#{v[0]} = #{v[1]}" }.join("\n\r")
            when input == 'ast'
              pp ast
            when input != ""
              g = @grammar.parse(input)
              ast = @transform.apply(g)
              puts @interpreter.run(ast)
            end
          rescue Exception => e
            puts e
            puts e.backtrace
          end
        end
      rescue Exception => e
        puts e
        puts e.backtrace
      end
    end

    def heading
      %q{
This is Kalc, a small line-based language.
More information about Kalc can be found at https://github.com/mrcsparker/kalc.

Kalc is free software, provided as is, with no warranty.
      }
    end

  end
end
