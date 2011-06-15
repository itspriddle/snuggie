$:.unshift 'lib'

require 'rake/testtask'

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = FileList['test/**/*_test.rb']
end

task :default => :test

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/snuggie.rb -I ./lib"
end

desc "Push a new version to rubygems.org"
task :publish do
  require 'snuggie/version'

  ver = Snuggie::Version

  mkdir("pkg") unless File.exists?("pkg")

  sh "gem build snuggie.gemspec"
  sh "gem push snuggie-#{ver}.gem"
  sh "git tag -a -m 'Snuggie v#{ver}' v#{ver}"
  sh "git push origin v#{ver}"
  sh "git push origin master"
  sh "mv snuggie-#{ver}.gem pkg"
end
