require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

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

desc 'Console mode'
task :console do
  require 'irb'
  require 'lib/pismo'
  require 'open-uri'
  @d = Pismo.document(ARGV[1] || open('./test/corpus/bbcnews.html'))
  
  # Get around IRB's issues with ARGV..
  ARGV = []
  IRB.start
end