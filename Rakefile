require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "crowd_rails"
    gem.summary = %Q{Single Sign On for Atlassian Crowd 2.0 with Ruby on Rails}
    gem.description = %Q{Single Sign On for Atlassian Crowd 2.0 with Ruby on Rails}
    gem.email = "post @nospam@ stefanwille.com"
    gem.homepage = "http://github.com/stefanwille/crowd_rails"
    gem.authors = ["Stefan Wille"]
    gem.add_dependency "crowd-stefanwille", "= 0.5.11"
    # Silence a warning about missing rubyforge_project
    gem.rubyforge_project = "nowarning"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

def version
  File.exist?('VERSION') ? File.read('VERSION') : ""
end

task :push => [:test, :build] do
  system("gem push pkg/crowd_rails-#{version}.gem")
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
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "crowd_rails #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

