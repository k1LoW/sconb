# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sconb/version'

Gem::Specification.new do |spec|
  spec.name          = "sconb"
  spec.version       = Sconb::VERSION
  spec.authors       = ["k1LoW"]
  spec.email         = ["k1lowxb@gmail.com"]
  spec.summary       = %q{Ssh CONfig Buckup tool.}
  spec.description   = %q{Ssh CONfig Buckup tool.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "net-ssh"
  spec.add_runtime_dependency "json"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "coveralls"
  spec.add_dependency "thor"  
end
