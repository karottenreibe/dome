# This is Dome, a pure Ruby HTML DOM parser with very simple XPath support.
#
# If you want to find out more or need a tutorial, go to
# http://dome.rubyforge.org/
# You'll find a nice wiki there!
#
# Author::      Fabian Streitel (karottenreibe)
# Copyright::   Copyright (c) 2008 Fabian Streitel
# License::     Boost Software License 1.0
#               For further information regarding this license, you can go to
#               http://www.boost.org/LICENSE_1_0.txt
# Homepage::    http://dome.rubyforge.org/
# Git repo::    http://rubyforge.org/scm/?group_id=7589
#

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

$VERBOSE = nil

GEM_NAME        = 'Dome'
GEM_NAMESPACE   = 'Dome'
GEM_AUTHORS     = ['Fabian Streitel']
GEM_HOMEPAGE    = 'http://dome.rubyforge.org/'
GEM_RUBYFORGE   = 'dome'
GEM_SUMMARY     = "A pure Ruby HTML DOM parser with very simple XPath support"
GEM_EMAIL       = "karottenreibe @nospam@ gmail.com"

spec = Gem::Specification.new do |s|
    if ARGV.any? { |arg| arg == 'gem' }
        puts
        puts
        puts "Versioning policy:"
        puts "1 = implementation details changed"
        puts "2 = compatible new feature"
        puts "3 = incompatible changes"
        puts
        puts "Last build: " + (Dir['pkg/*'].sort)[-1].to_s
        print "Enter version number > "
        ver = STDIN.gets.strip
        print "Enter changelog > "
        chl = STDIN.gets

        File.open('CHANGELOG', 'a') do |f|
            f.write "#{ver.ljust 8} :: #{chl}"
        end
    end

    s.platform          =   Gem::Platform::RUBY
    s.name              =   GEM_NAME
    s.version           =   ver || "99"
    s.authors           =   GEM_AUTHORS
    s.email             =   GEM_EMAIL
    s.homepage          =   GEM_HOMEPAGE
    s.rubyforge_project =   GEM_RUBYFORGE
    s.summary           =   GEM_SUMMARY
    s.files             =   FileList['lib/**/*.rb', 'test/**/*', '[A-Z]*'].to_a
    s.require_path      =   "lib"
    s.autorequire       =   "dome/parser"
    s.test_files        =   FileList['test/**/*.rb']
    s.has_rdoc          =   true
    s.extra_rdoc_files  =   ["README", "CHANGELOG", "LICENSE"]
    s.add_dependency        'Spectre', '>= 0.0.0'
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

task :gem => "pkg/#{GEM_NAME}-#{spec.version}.gem" do
    puts "generated gem"
end

Rake::RDocTask.new :real_doc do |rdoc|
    rdoc.rdoc_files.include "lib/**/*.rb"
end

task :doc => [:real_doc] do
    sh 'rm -r rdoc' if File::exists? 'rdoc'
    sh 'mv html rdoc'
end

task :clean do
    sh 'rm -r rdoc'
    sh 'rm -r pkg'
end

Rake::TestTask.new do |t|
    t.libs << "test" << "lib/dome"
    t.test_files = ['test/tests.rb']
    t.verbose = true
end

task :upload => [:rdoc] do
    sh "rsync -azv --no-perms --no-times rdoc/* karottenreibe@rubyforge.org:/var/www/gforge-projects/#{GEM_RUBYFORGE}/rdoc/"
    sh "rsync -azv --no-perms --no-times homepage/* karottenreibe@rubyforge.org:/var/www/gforge-projects/#{GEM_RUBYFORGE}/"
end

task :sftp do
    sh "sftp karottenreibe@rubyforge.org:/var/www/gforge-projects/#{GEM_RUBYFORGE}/"
end

task :install => [:package] do
    sh "sudo gem install pkg/#{GEM_NAME}-#{spec.version}.gem"
    sh "rm pkg/#{GEM_NAME}-#{spec.version}.gem"
end

task :rcov do
    sh "rcov -Ilib test/*_tests.rb"
    sh "firefox coverage/index.html &"
end

task :heckle do
    print "class: "
    klass = STDIN.gets.strip
    print "method (leave empty for all methods): "
    meth = STDIN.gets.strip

    v = $VERBOSE
    $VERBOSE = nil
    sh "heckle -t test/tests.rb '#{GEM_NAMESPACE ? GEM_NAMESPACE + "::" : ""}#{klass}' #{meth.empty? ? "" : "'" + meth + "'"} | less"
    $VERBOSE = v
end

task :default => [:gem, :doc]
task :all => [:clean, :gem, :doc, :test]
task :rdoc => [:doc]

