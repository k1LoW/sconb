# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sconb/version'

Gem::Specification.new do |spec|
  spec.name          = 'sconb'
  spec.version       = Sconb::VERSION
  spec.authors       = ['k1LoW']
  spec.email         = ['k1lowxb@gmail.com']
  spec.summary       = 'Ssh CONfig Buckup tool.'
  spec.description   = 'Ssh CONfig Buckup tool.'
  spec.homepage      = 'https://github.com/k1LoW/sconb'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.1'
  spec.add_runtime_dependency 'thor'
  spec.add_runtime_dependency 'net-ssh'
  spec.add_runtime_dependency 'json'
  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'octorelease'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'pry'
end
