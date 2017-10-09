# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cartography/version'

Gem::Specification.new do |s|
  s.name          = 'cartography'
  s.version       = Cartography::VERSION
  s.authors       = ['Nicolas PROCUREUR']
  s.email         = ['nprocureur@ekylibre.com']

  s.summary       = 'Map tools to display and edit shapes'
  s.homepage      = 'https://github.com/ekylibre/cartography'
  s.license       = 'MIT'

  s.files = Dir['{app,config,lib}/**/*', 'vendor/assets/components/*/dist/*','Rakefile', 'README.md']

  s.require_paths = ['lib']

  s.add_development_dependency 'bundler', '~> 1.14'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'byebug'
end
