begin
  require 'readline'
rescue LoadError
  require 'reline'
  Readline = Reline unless defined?(Readline)
end

require 'pp'
require 'kalc' unless defined?(Kalc::Runner)

# Interactive shell for evaluating Kalc expressions.
module Kalc
  # Provides the interactive read/eval/print loop.
  class Repl
    COMMANDS = %w[quit exit functions variables ast reload].freeze

    # Rebuilds the REPL runtime state.
    #
    # @return [void]
    def load_env
      @kalc = Kalc::Runner.new(debug_mode?)
    end

    # Starts the interactive read/eval/print loop.
    #
    # @return [void]
    def run
      puts heading
      load_env

      puts 'You are ready to go. Have fun!'
      puts
      configure_completion

      loop do
        input = Readline.readline(prompt, true)
        break unless input
        break if process_input(input) == :exit
      end
    rescue Interrupt
      puts
    rescue SecurityError, StandardError => e
      report_error(e)
    end

    # Returns the banner shown when the REPL starts.
    #
    # @return [String]
    def heading
      <<~TEXT
        This is Kalc, a small line-based language.
        More information about Kalc can be found at https://github.com/mrcsparker/kalc.

        Kalc is free software, provided as is, with no warranty.
      TEXT
    end

    private

    # Configures tab completion for builtin and shell commands.
    #
    # @return [void]
    def configure_completion
      Readline.completion_append_character = ''
      Readline.completion_proc = proc { |text| completions.grep(/^#{Regexp.escape(text)}/) }
    end

    # Returns the available completion entries.
    #
    # @return [Array<String>]
    def completions
      (COMMANDS + @kalc.interpreter.env.functions.keys).sort
    end

    # Returns the prompt for the current Kalc version.
    #
    # @return [String]
    def prompt
      "kalc-#{Kalc::VERSION} > "
    end

    # Returns whether the command requests the REPL to exit.
    #
    # @param command [String]
    # @return [Boolean]
    def exit_command?(command)
      %w[quit exit].include?(command)
    end

    # Processes one line of REPL input.
    #
    # @param input [String]
    # @return [Symbol]
    def process_input(input)
      command = input.strip
      return :exit if exit_command?(command)
      return :continue if command.empty?

      execute(command)
      :continue
    rescue SecurityError, StandardError => e
      report_error(e)
      :continue
    end

    # Executes either a REPL command or a Kalc expression.
    #
    # @param command [String]
    # @return [void]
    def execute(command)
      case command
      when 'functions'
        puts @kalc.interpreter.env.functions.keys.join(', ')
      when 'variables'
        puts @kalc.interpreter.env.variables.map { |name, value| "#{name} = #{display_value(value)}" }.join("\n")
      when 'reload'
        load_env
      when 'ast'
        pp @kalc.ast
      else
        puts @kalc.run(command)
      end
    end

    # Formats a stored variable for display.
    #
    # @param value [Object]
    # @return [Object]
    def display_value(value)
      value.is_a?(Kalc::Ast::Formula) ? value.eval(@kalc.interpreter.env) : value
    end

    # Prints a user-facing error message and an optional backtrace in debug mode.
    #
    # @param error [Exception]
    # @return [void]
    def report_error(error)
      if error.is_a?(Kalc::ParseError)
        puts error.message
      else
        puts "#{error.class}: #{error.message}"
      end

      return unless debug_mode? && error.backtrace

      puts error.backtrace
    end

    # Returns whether verbose debug output is enabled for the REPL.
    #
    # @return [Boolean]
    def debug_mode?
      ENV['KALC_DEBUG'] == '1'
    end
  end
end
