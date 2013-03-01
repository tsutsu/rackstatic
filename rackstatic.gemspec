require File.expand_path("../lib/rack/static-builder", __FILE__)

Gem::Specification.new do |s|
  s.name              = 'rackstatic'
  s.rubyforge_project = 'rackstatic'

  s.platform          = Gem::Platform::RUBY
  s.version           = Rack::StaticBuilder::VERSION

  s.summary           = "creates a static copy of your rack app"
  s.description       = "Stop treating static-site generators differently than web frameworks. Build your static site using any rack-compatible web framework, then generate a static version with the rackstatic(1) command."
  s.license           = 'MIT'

  s.authors           = ["Sean Keith McAuley"]
  s.email             = 'tsu@peripia.com'
  s.homepage          = 'https://github.com/tsutsu/rackstatic'

  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables       = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths     = ["lib"]

  s.add_dependency('rack', '>= 1.5.2')
  s.add_dependency('rack-test', '>= 0.6.2')
  s.add_dependency('nokogiri', '>= 0.5.6')
end
