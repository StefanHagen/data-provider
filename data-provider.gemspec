Gem::Specification.new do |s|
  GEM_NAME=
  PKG_VERSION

  s.name = "data-provider"
  s.version = '0.1.0'
  s.files = `git ls-files`.split($/)
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_development_dependency 'rspec'

  s.author = "Mark van de Korput"
  s.email = "dr.theman@gmail.com"
  s.date = '2015-07-14'
  s.description = %q{A library of Ruby classes to help create consistent data interfaces}
  s.summary = %q{A library of Ruby classes to help create consistent data interfaces}
  s.homepage = %q{https://github.com/markkorput/data-provider}
  s.license = "MIT"
end
