# -*- encoding: utf-8 -*-
require 'rake'

Gem::Specification.new do |s|
  s.name          = 'my_stuff-multidb'
  s.version       = '0.0.1'
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
  s.executables = ['my_stuff-multidb-unmanagle']
end
