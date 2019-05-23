# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'image_optim'
  s.version     = '0.26.4'
  s.summary     = %q{Command line tool and ruby interface to optimize (lossless compress, optionally lossy) jpeg, png, gif and svg images using external utilities (advpng, gifsicle, jhead, jpeg-recompress, jpegoptim, jpegrescan, jpegtran, optipng, pngcrush, pngout, pngquant, svgo)}
  s.homepage    = "http://github.com/toy/#{s.name}"
  s.authors     = ['Ivan Kuchin']
  s.license     = 'MIT'

  s.rubyforge_project = s.name

  s.metadata = {
    'bug_tracker_uri'   => "https://github.com/toy/#{s.name}/issues",
    'changelog_uri'     => "https://github.com/toy/#{s.name}/blob/master/CHANGELOG.markdown",
    'documentation_uri' => "https://www.rubydoc.info/gems/#{s.name}/#{s.version}",
    'source_code_uri'   => "https://github.com/toy/#{s.name}",
  }

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w[lib]

  s.post_install_message = <<-EOF
Rails image assets optimization is extracted into image_optim_rails gem
You can safely remove `config.assets.image_optim = false` if you are not going to use that gem
EOF

  s.add_dependency 'fspath', '~> 3.0'
  s.add_dependency 'image_size', '>= 1.5', '< 3'
  s.add_dependency 'exifr', '~> 1.2', '>= 1.2.2'
  s.add_dependency 'progress', '~> 3.0', '>= 3.0.1'
  s.add_dependency 'in_threads', '~> 1.3'

  s.add_development_dependency 'image_optim_pack', '~> 0.2', '>= 0.2.2'
  s.add_development_dependency 'rspec', '~> 3.0'
  if RUBY_VERSION >= '2.2' && !Gem.win_platform? && !defined?(JRUBY_VERSION)
    s.add_development_dependency 'rubocop', '~> 0.59'
  end
end
