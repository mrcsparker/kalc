$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'kalc/version'

root_files = %w[
  .gitignore
  .rspec
  .rubocop.yml
  .ruby-version
  .tool-versions
  CHANGELOG.md
  CONTRIBUTING.md
  Gemfile
  Gemfile.lock
  LICENSE
  README.md
  Rakefile
  kalc.gemspec
].freeze

package_globs = %w[
  .github/workflows/*.yml
  bin/*
  examples/*.kalc
  lib/**/*.kalc
  lib/**/*.rb
  spec/**/*_spec.rb
  spec/spec_helper.rb
].freeze

files = Dir.chdir(__dir__) do
  (root_files + package_globs.flat_map { |glob| Dir.glob(glob) })
    .select { |path| File.file?(path) }
    .sort
    .uniq
end

executables = Dir.chdir(__dir__) do
  Dir.glob('bin/*')
     .select { |path| File.file?(path) }
     .map { |path| File.basename(path) }
     .sort
end

Gem::Specification.new do |s|
  s.name = 'kalc'
  s.version = Kalc::VERSION
  s.authors = ['Chris Parker']
  s.email = %w[mrcsparker@gmail.com]
  s.homepage = 'https://github.com/mrcsparker/kalc'
  s.license = 'MIT'
  s.summary = 'Small calculation language.'
  s.description = "Calculation language slightly based on Excel's formula language."
  s.required_ruby_version = '>= 3.2'
  s.metadata = {
    'bug_tracker_uri' => "#{s.homepage}/issues",
    'changelog_uri' => "#{s.homepage}/blob/main/CHANGELOG.md",
    'documentation_uri' => "#{s.homepage}#readme",
    'source_code_uri' => s.homepage,
    'rubygems_mfa_required' => 'true'
  }

  s.files = files
  s.executables = executables
  s.require_paths = %w[lib]

  s.add_dependency 'bigdecimal'
  s.add_dependency 'logger'
  s.add_dependency 'reline'
end
