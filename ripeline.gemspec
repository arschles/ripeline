spec = Gem::Specification.new do |s|
  s.name = 'ripeline'
  s.version = '0.0.1'
  s.summary = "Build a distributed pipeline with ruby"
  s.description = %{A framework that makes it easy to build, run, coordinate and manage pipeline stages.}
  s.files = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
  s.require_path = 'lib'
  s.author = "Aaron Schlesinger"
  s.email = "arschles@gmail.com"
  s.homepage = "http://github.com/arschles/ripeline"
  
  s.add_runtime_dependency 'redis', '~> 2.2.0', '>= 2.2.0'
  s.add_runtime_dependency 'redis-namespace', '~> 1.0.2', '>= 1.0.2'
  s.add_runtime_dependency 'mongo', '~> 1.3.1', '>= 1.3.1'
  s.add_runtime_dependency 'json', '~> 1.5.1', '>= 1.5.1'
  s.add_runtime_dependency 'uuid', '~> 2.3.2', '>= 2.3.2'
end