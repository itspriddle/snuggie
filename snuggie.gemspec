$:.unshift 'lib'

require 'snuggie/version'

Gem::Specification.new do |s|
  s.platform   = Gem::Platform::RUBY
  s.name       = 'snuggie'
  s.version    = Snuggie::Version
  s.date       = Time.now.strftime('%Y-%m-%d')
  s.summary    = 'Snuggie wraps the Softaculous API in a warm, loving ruby embrace'
  s.homepage   = 'https://github.com/site5/snuggie'
  s.authors    = ['Joshua Priddle']
  s.email      = 'jpriddle@site5.com'
  s.license    = 'MIT'

  s.files      = %w[ Rakefile README.markdown ]
  s.files     += Dir['lib/**/*']
  s.files     += Dir['test/**/*']

  s.extra_rdoc_files = ['README.markdown']
  s.rdoc_options     = ["--charset=UTF-8"]

  s.add_runtime_dependency 'php-serialize',      '~> 1.1.0'
  s.add_runtime_dependency 'faraday',            '~> 0.8.9'
  s.add_runtime_dependency 'faraday_middleware', '~> 0.9.0'
  s.add_runtime_dependency('jruby-openssl', '~> 0.7.4') if RUBY_PLATFORM == 'java'

  s.add_development_dependency 'rake', '~> 0.9.2.2'
  s.add_development_dependency 'fakeweb', '~> 1.3.0'

  s.description = <<-DESC
    Snuggie wraps the Softaculous API in a warm, loving ruby embrace.
  DESC
end

