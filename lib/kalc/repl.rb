require 'readline'
require 'pp'

require 'parslet/convenience'

module Kalc
  class Repl
    def load_env
      @kalc = Kalc::Runner.new(true)
    end

    def run
      puts heading

      # Load Kalc with debug
      load_env

      puts 'You are ready to go.  Have fun!'
      puts ''

      function_list = %w[quit exit functions variables ast] + @kalc.interpreter.env.functions.map(&:first)

      begin
        comp = proc { |s| function_list.grep(/^#{Regexp.escape(s)}/) }
        Readline.completion_append_character = ''
        Readline.completion_proc = comp

        while (input = Readline.readline("kalc-#{Kalc::VERSION} > ", true))
          begin
            if input == 'quit' || input == 'exit'
              break
            elsif input == 'functions'
              puts @kalc.interpreter.env.functions.map(&:first).join(', ')
            elsif input == 'variables'
              puts @kalc.interpreter.env.variables.map { |v| "#{v[0]} = #{v[1]}" }.join("\n\r")
            elsif input == 'reload'
              load_env
            elsif input == 'ast'
              pp @kalc.ast
            elsif input != ''
              puts @kalc.run(input)
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
      '
        This is Kalc, a small line-based language.
        More information about Kalc can be found at https://github.com/mrcsparker/kalc.

        Kalc is free software, provided as is, with no warranty.
      '
    end
  end
end
