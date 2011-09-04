# -*- encoding: utf-8 -*-
require 'rake'

Gem::Specification.new do |s|
  s.name          = 'my_stuff-multidb'
  s.version       = '0.0.2'
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Fred Emmott']
  s.email         = ['mail@fredemmott.co.uk']
  s.require_paths = ['lib']
  s.homepage      = 'https://github.com/fredemmott/my_stuff-multidb'
  s.summary       = 'ActiveRecord sharding/slaves library'
  s.description   = ''
  s.license       = 'ISC'
  s.files         = FileList[
    'COPYING',
    'README.rdoc',
    'bin/*',
    'lib/**/*.rb',
  ].to_a
  s.executables = ['my_stuff-multidb-unmangle']

  s.add_dependency 'my_stuff-logger', '~> 0.0.3'
  s.add_dependency 'activerecord', '~> 3.0.7'
end
