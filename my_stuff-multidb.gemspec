# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name          = 'my_stuff-multidb'
  s.version       = '0.0.3'
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Fred Emmott']
  s.email         = ['mail@fredemmott.co.uk']
  s.require_paths = ['lib']
  s.homepage      = 'https://github.com/fredemmott/my_stuff-multidb'
  s.summary       = 'ActiveRecord sharding/slaves library'
  s.description   = ''
  s.license       = 'ISC'
  s.files         = Dir[
    'COPYING',
    'README.rdoc',
    'bin/*',
    'lib/**/*.rb',
  ]
  s.executables = ['my_stuff-multidb-unmangle']

  s.add_dependency 'activerecord', '~> 3.2', '>= 3.2.1'
end
