# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "kalc/version"
#
Gem::Specification.new do |s|
  s.name        = "kalc"
  s.version     = Kalc::VERSION
  s.authors     = ["Chris Parker"]
  s.email       = %w(mrcsparker@gmail.com)
  s.homepage    = "https://github.com/mrcsparker/kalc"
  s.summary     = %q{Small calculation language.}
  s.description = %q{Calculation language slightly based on Excel's formula language.}

  s.rubyforge_project = "kalc"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)

  # specify any dependencies here; for example:
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_runtime_dependency "parslet", "~> 1.4"
end
