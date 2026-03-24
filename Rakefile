require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  nil
end

desc 'Run the test suite'
task default: :spec
