require 'readline'
require 'pp'

require 'parslet/convenience'

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
      @interpreter.load_stdlibs(@grammar, @transform)

      puts "You are ready to go.  Have fun!"
      puts ""

      ast = nil

      function_list = [
        'quit', 'exit', 'functions', 'variables', 'ast'
      ] + @interpreter.env.functions.map { |f| f.first }

      begin
        comp = proc { |s| function_list.grep( /^#{Regexp.escape(s)}/ ) }
        Readline.completion_append_character = ""
        Readline.completion_proc = comp

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
              g = @grammar.parse_with_debug(input)
              ast = @transform.apply(g)
              puts @interpreter.run(ast)
            end
          rescue Parslet::ParseFailed => e
            puts e, g.root.error_tree
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
