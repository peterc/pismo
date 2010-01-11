require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "csteamer"
    gem.summary = %Q{Extracts or retrieves content-related metadata from HTML pages and remote services}
    gem.description = %Q{CSteamer "steams" your content for data you can use in an organized way, such as a summary/first paragraph, del.icio.us tags, first image used in the content block, etc.}
    gem.email = "git@peterc.org"
    gem.homepage = "http://github.com/peterc/csteamer"
    gem.authors = ["Peter Cooper"]
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    gem.add_development_dependency "mhennemeyer-matchy", ">= 0"
    gem.add_dependency "nokogiri"
    gem.add_dependency "loofah"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "csteamer #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Automatically run something when code is changed'
task :on_update do
  require 'find'
  files = {}
 
  loop do
    changed = false
    Find.find(File.dirname(__FILE__)) do |file|
      next unless file =~ /\.rb$/
      ctime = File.ctime(file).to_i
 
      if ctime != files[file]
        files[file] = ctime
        changed = true
      end
    end
 
    if changed
      system ARGV[1] || 'rake'
      puts "\n" + Time.now.to_s
    end
 
    sleep 4
  end
end