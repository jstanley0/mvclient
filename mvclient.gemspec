Gem::Specification.new do |s|
  s.name        = 'mvclient'
  s.version     = '0.0.1'
  s.date        = '2015-04-08'
  s.summary     = "Motivosity API Client"
  s.description = "A minimal Motivosity API v1 wrapper for Ruby, plus a command-line tool"
  s.authors     = ["Jeremy Stanley"]
  s.email       = 'jstanley0@gmail.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'http://github.com/jstanley0/mvclient'
  s.license     = 'Apache'
  s.bindir      = 'bin'
  s.executables << 'mvclient'
  s.required_ruby_version = '>= 1.9.3'
  s.add_dependency 'httparty', '~> 0'
  s.add_dependency 'http-cookie', '~> 1'
end