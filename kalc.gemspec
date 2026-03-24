$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'kalc/version'
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

  s.files = `git ls-files`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = %w[lib]

  s.add_dependency 'bigdecimal'
  s.add_dependency 'logger'
  s.add_dependency 'reline'
end
