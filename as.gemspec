# -*- encoding: utf-8 -*-
require File.expand_path('../lib/as/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Julien Ammous"]
  gem.email         = ["schmurfy@gmail.com"]
  gem.description   = %q{...}
  gem.summary       = %q{..}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.name          = "as"
  gem.require_paths = ["lib"]
  gem.version       = AS::VERSION
  
  gem.add_dependency 'rack'
  gem.add_dependency 'ffi'
  gem.add_dependency 'ox'
  gem.add_dependency 'msgpack'
  # gem.add_dependency 'ffi-wbxml'
end
