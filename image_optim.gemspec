# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'image_optim'
  s.version     = '0.20.2'
  s.summary     = %q{Optimize (lossless compress, optionally lossy) images (jpeg, png, gif, svg) using external utilities (advpng, gifsicle, jhead, jpeg-recompress, jpegoptim, jpegrescan, jpegtran, optipng, pngcrush, pngout, pngquant, svgo)}
  s.homepage    = "http://github.com/toy/#{s.name}"
  s.authors     = ['Ivan Kuchin']
  s.license     = 'MIT'

  s.rubyforge_project = s.name

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w[lib]

  s.add_dependency 'fspath', '~> 2.1'
  s.add_dependency 'image_size', '~> 1.3'
  s.add_dependency 'exifr', '~> 1.1', '>= 1.1.3'
  s.add_dependency 'progress', '~> 3.0', '>= 3.0.1'
  s.add_dependency 'in_threads', '~> 1.3'

  s.add_development_dependency 'image_optim_pack', '~> 0.2'
  s.add_development_dependency 'rspec', '~> 3.0'
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('1.9.3')
    s.add_development_dependency 'rubocop', '~> 0.27'
  end
  s.add_development_dependency 'haml', '~> 4.0'
end
