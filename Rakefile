require 'rubygems'
require 'jeweler'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

task :release do
    sh "vim HISTORY.markdown"
    sh "vim README.markdown"
    sh "git commit -a -m 'prerelease adjustments'; true"
end

Jeweler::Tasks.new do |gem|
    gem.name = "dome"
    gem.summary = gem.description = "A pure Ruby HTML DOM parser with CSS3 support"
    gem.email = "karottenreibe@gmail.com"
    gem.homepage = "http://github.com/karottenreibe/dome"
    gem.authors = ["Fabian Streitel"]
    gem.rubyforge_project = 'k-gems'
end

Jeweler::RubyforgeTasks.new

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'Dome'
  rdoc.rdoc_files.include('lib/*.rb')
  rdoc.rdoc_files.include('lib/*/**/*.rb')
  rdoc.rdoc_files.include(%w{README.markdown LICENSE.txt HISTORY.markdown})
end

Rake::TestTask.new do |t|
    t.libs << "test" << "lib/dome"
    t.test_files = ['test/tests.rb']
    t.verbose = true
end

# code coverage and test analysis
#...............................

task :rcov do
    sh "rcov -Ilib test/*_tests.rb"
    sh "firefox coverage/index.html &"
end

task :heckle do
    print "class: "
    klass = STDIN.gets.strip
    print "method (leave empty for all methods): "
    meth = STDIN.gets.strip

    sh "heckle -t test/tests.rb '#{GEM_NAMESPACE ? GEM_NAMESPACE + "::" : ""}#{klass}' #{meth.empty? ? "" : "'" + meth + "'"} | tee heckle.log"
    sh "vim heckle.log"
end

