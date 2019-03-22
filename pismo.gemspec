# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pismo/version"

Gem::Specification.new do |s|
  s.name        = "pismo"
  s.version     = Pismo::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Peter Cooper", "William Flanagan"]
  s.email       = ["git@peterc.org", "wflanagan@audienti.com"]
  s.homepage    = "http://github.com/omalab/pismo"
  s.description = %q{Pismo extracts and retrieves content-related metadata from HTML pages - you can use the resulting data in an organized way, such as a summary/first paragraph, body text, keywords, RSS feed URL, favicon, etc.}
  s.summary     = %q{Extracts or retrieves content-related metadata from HTML pages}
  s.date        = %q{2019-03-15}
  s.default_executable = %q{pismo}

  s.rubyforge_project = "pismo"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Note, this has additional dependencies in the Gemfile

  s.add_development_dependency(%q<shoulda>, [">= 0"])
  s.add_development_dependency(%q<mocha>, [">= 0"])
  s.add_development_dependency(%q<rake>, [">= 0"])
  s.add_dependency('twitter-text')
  s.add_dependency(%q<awesome_print>, [">= 0"])
  s.add_dependency(%q<nokogiri>, [">= 0"])
  s.add_dependency(%q<sanitize>, [">= 0"])
  s.add_dependency(%q<fast-stemmer>, [">= 0"])
  s.add_dependency(%q<chronic>, [">= 0"])
  s.add_dependency(%q<phrasie>, [">= 0.1.4"])
  s.add_dependency(%q<fastimage>, [">= 1"])
  s.add_dependency(%q<htmlentities>)
end
