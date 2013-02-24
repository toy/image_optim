# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'image_optim'
  s.version     = '0.7.2'
  s.summary     = %q{Optimize (lossless compress) images (jpeg, png, gif) using external utilities (advpng, gifsicle, jpegoptim, jpegtran, optipng, pngcrush, pngout)}
  s.homepage    = "http://github.com/toy/#{s.name}"
  s.authors     = ['Ivan Kuchin']
  s.license     = 'MIT'

  s.rubyforge_project = s.name

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w[lib]

  s.add_dependency 'fspath', '~> 2.0.3'
  s.add_dependency 'image_size', '~> 1.1.2'
  s.add_dependency 'progress', '~> 2.4.0'
  s.add_dependency 'in_threads', '~> 1.1.1'
  s.add_development_dependency 'rspec'
end
