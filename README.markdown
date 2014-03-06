# image_optim

Optimize (lossless compress) images (jpeg, png, gif, svg) using external utilities:

* [advpng](http://advancemame.sourceforge.net/doc-advpng.html) from [AdvanceCOMP](http://advancemame.sourceforge.net/comp-readme.html)
* [gifsicle](http://www.lcdf.org/gifsicle/)
* [jhead](http://www.sentex.net/~mwandel/jhead/)
* [jpegoptim](http://www.kokkonen.net/tjko/projects.html)
* jpegtran from [Independent JPEG Group's JPEG library](http://www.ijg.org/)
* [optipng](http://optipng.sourceforge.net/)
* [pngcrush](http://pmt.sourceforge.net/pngcrush/)
* [pngout](http://www.advsys.net/ken/util/pngout.htm)
* [svgo](https://github.com/svg/svgo)
* [pngquant](http://pngquant.org/)

Based on [ImageOptim.app](http://imageoptim.com/).

[![Gem Version](https://badge.fury.io/rb/image_optim.png)](http://badge.fury.io/rb/image_optim)
[![Build Status](https://travis-ci.org/toy/image_optim.png?branch=master)](https://travis-ci.org/toy/image_optim)
[![Code Climate](https://codeclimate.com/github/toy/image_optim.png)](https://codeclimate.com/github/toy/image_optim)
[![Dependency Status](https://gemnasium.com/toy/image_optim.png)](https://gemnasium.com/toy/image_optim)

## Gem installation

```sh
gem install image_optim
```

### Bundler

Add to your `Gemfile`:
```ruby
gem 'image_optim'
```

With version:
```ruby
gem 'image_optim', '~> 0.11'
```

If you want to check latest changes:
```ruby
gem 'image_optim', :git => 'git://github.com/toy/image_optim.git'
```

## Binaries location

Simplest way for `image_optim` to locate binaries is to install them in common location present in `PATH` (see [Binaries installation](#binaries-installation)).

If you cannot install to common location, then install to custom one and add it to `PATH`.

Specify custom bin location using `XXX_BIN` environment variable (`JPEGOPTIM_BIN`, `OPTIPNG_BIN`, …).

Besides permanently setting environment variables in `~/.profile`, `~/.bash_profile`, `~/.bashrc`, `~/.zshrc`, … they can be set:

* before command:

  `PATH="/custom/location:$PATH" image_optim *.jpg`

  for example:

  `PATH="/Applications/ImageOptim.app/Contents/MacOS:$PATH" image_optim *.jpg`

* inside script:

  `ENV['PATH'] = "/custom/location:#{ENV['PATH']}"; ImageOptim.optimize_images([…])`

  for example:

  `ENV['PATH'] = "/Applications/ImageOptim.app/Contents/MacOS:#{ENV['PATH']}"; ImageOptim.optimize_images([…])`

## Binaries installation

### Linux - Debian/Ubuntu

```bash
sudo apt-get install -y advancecomp gifsicle jhead jpegoptim libjpeg-progs optipng pngcrush
```

### Linux - RHEL/Fedora/Centos

```bash
sudo yum install -y advancecomp gifsicle jhead libjpeg optipng
```

You will also need to install `jpegoptim` and `pngcrush` from source:

#### jpegoptim

```bash
cd /tmp
curl -O http://www.kokkonen.net/tjko/src/jpegoptim-1.3.0.tar.gz
tar zxf jpegoptim-1.3.0.tar.gz
cd jpegoptim-1.3.0
./configure && make && make install
```

#### pngcrush

```bash
cd /tmp
curl -O http://iweb.dl.sourceforge.net/project/pmt/pngcrush/1.7.70/pngcrush-1.7.70.tar.gz
tar zxf pngcrush-1.7.70.tar.gz
cd pngcrush-1.7.70
make && cp -f pngcrush /usr/local/bin
```

### OS X: Macports

```bash
sudo port install advancecomp gifsicle jhead jpegoptim jpeg optipng pngcrush pngquant
```

### OS X: Brew

```bash
brew install advancecomp gifsicle jhead jpegoptim jpeg optipng pngcrush
```

### pngout installation (optional)

You can install `pngout` by downloading and installing the [binary versions](http://www.jonof.id.au/kenutils).

_Note: pngout is free to use even in commercial soft, but you can not redistribute, repackage or reuse it without consent and agreement of creator. [license](http://advsys.net/ken/utils.htm#pngoutkziplicense)_

### svgo installation (optional)

`svgo` is available from NPM.

```bash
npm install -g svgo
```

## Usage

### From shell

```sh
image_optim *.{jpg,png,gif,svg}

image_optim -h
```

### From ruby

Initilize optimizer (or you can call optimization methods directly on `ImageOptim`):

```ruby
image_optim = ImageOptim.new

image_optim = ImageOptim.new(:pngout => false)

image_optim = ImageOptim.new(:nice => 20)
```

Optimize image getting temp path:

```ruby
image_optim.optimize_image('a.png')
```

Optimize image in place:

```ruby
image_optim.optimize_image!('b.jpg')
```

Optimize image data:

```ruby
image_optim.optimize_image_data(data)
```

Multiple images:

```ruby
image_optim.optimize_images(Dir['*.png']) do |unoptimized, optimized|
  if optimized
    puts "#{unoptimized} => #{optimized}"
  end
end

image_optim.optimize_images!(Dir['*.*'])

image_optim.optimize_images_data(datas)
```

### From rails

`ImageOptim::Railtie` will automatically register sprockets preprocessor unless you set `config.assets.image_optim = false` or `config.assets.compress = false` (later for partial rails 3 compatibility).

You can provide options for image_optim used for preprocessor through config `config.assets.image_optim = {nice: 20, svgo: false}` (ruby1.8 style: `{:nice => 20, :svgo => false}`).
Check available options in [options section](#options).

Image optimization can be time consuming, so depending on your deployment process you may prefer to optimize original asset files.

## Configuration

Configuration in YAML format will be read and prepanded to options from two paths:

* `$XDG_CONFIG_HOME/image_optim.yml` (by default `~/.config/image_optim.yml`)
* `.image_optim.yml` in current working directory

Example configuration:

```yaml
nice: 20
pngout: false # disable
optipng:
  level: 5
```

## Options

* `:nice` — Nice level *(defaults to 10)*
* `:threads` — Number of threads or disable *(defaults to number of processors)*
* `:verbose` — Verbose output *(defaults to false)*

Worker can be disabled by passing false instead of options hash.

<!---<worker-options>-->

### pngcrush
* `:chunks` — List of chunks to remove or 'alla' - all except tRNS/transparency or 'allb' - all except tRNS and gAMA/gamma *(defaults to alla)*
* `:fix` — Fix otherwise fatal conditions such as bad CRCs *(defaults to false)*
* `:brute` — Brute force try all methods, very time-consuming and generally not worthwhile *(defaults to false)*

### pngout
* `:copy_chunks` — Copy optional chunks *(defaults to false)*
* `:strategy` — Strategy: 0 - xtreme, 1 - intense, 2 - longest Match, 3 - huffman Only, 4 - uncompressed *(defaults to 0)*

### optipng
* `:level` — Optimization level preset 0 is least, 7 is best *(defaults to 6)*
* `:interlace` — Interlace, true - interlace on, false - interlace off, nil - as is in original image *(defaults to false)*

### advpng
* `:level` — Compression level: 0 - don't compress, 1 - fast, 2 - normal, 3 - extra, 4 - extreme *(defaults to 4)*

### jpegoptim
* `:strip` — List of extra markers to strip: comments, exif, iptc, icc or all *(defaults to all)*
* `:max_quality` — Maximum image quality factor 0..100 *(defaults to 100)*

### jpegtran
* `:copy_chunks` — Copy all chunks *(defaults to false)*
* `:progressive` — Create progressive JPEG file *(defaults to true)*
* `:jpegrescan` — Use jpegtran through jpegrescan, ignore progressive option *(defaults to false)*

### gifsicle
* `:interlace` — Turn interlacing on *(defaults to false)*

<!---</worker-options>-->

## Copyright

Copyright (c) 2012-2014 Ivan Kuchin. See LICENSE.txt for details.
