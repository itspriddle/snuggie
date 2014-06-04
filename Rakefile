begin
  require 'bundler/gem_tasks'
  require 'rake/testtask'
rescue LoadError
  abort "Please run `bundle install` first"
end

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = FileList['test/**/*_test.rb']
end

task :default => :test
