# image_optim

Optimize (lossless compress) images (jpeg, png, gif) using external utilities:

* [advpng](http://advancemame.sourceforge.net/doc-advpng.html) from [AdvanceCOMP](http://advancemame.sourceforge.net/comp-readme.html)
* [gifsicle](http://www.lcdf.org/gifsicle/)
* [jhead](http://www.sentex.net/~mwandel/jhead/)
* [jpegoptim](http://www.kokkonen.net/tjko/projects.html)
* jpegtran from [Independent JPEG Group's JPEG library](http://www.ijg.org/)
* [optipng](http://optipng.sourceforge.net/)
* [pngcrush](http://pmt.sourceforge.net/pngcrush/)
* [pngout](http://www.advsys.net/ken/util/pngout.htm)
* [zopfli](https://code.google.com/p/zopfli/)

Based on [ImageOptim.app](http://imageoptim.com/).

[![Gem Version](https://badge.fury.io/rb/image_optim.png)](http://badge.fury.io/rb/image_optim)
[![Build Status](https://travis-ci.org/toy/image_optim.png?branch=master)](https://travis-ci.org/toy/image_optim)
[![Code Climate](https://codeclimate.com/github/toy/image_optim.png)](https://codeclimate.com/github/toy/image_optim)
[![Dependency Status](https://gemnasium.com/toy/image_optim.png)](https://gemnasium.com/toy/image_optim)

## Gem installation

    gem install image_optim

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

    sudo apt-get install -y advancecomp gifsicle jhead jpegoptim libjpeg-progs optipng pngcrush

### Linux - RHEL/Fedora/Centos

    sudo yum install -y advancecomp gifsicle jhead libjpeg optipng

You will also need to install `jpegoptim` and `pngcrush` from source:

#### jpegoptim

    cd /tmp
    curl -O http://www.kokkonen.net/tjko/src/jpegoptim-1.2.4.tar.gz
    tar zxf jpegoptim-1.2.4.tar.gz
    cd jpegoptim-1.2.4
    ./configure && make && make install

#### pngcrush

    cd /tmp
    curl -O http://iweb.dl.sourceforge.net/project/pmt/pngcrush/1.7.43/pngcrush-1.7.43.tar.gz
    tar zxf pngcrush-1.7.43.tar.gz
    cd pngcrush-1.7.43
    make && cp -f pngcrush /usr/local/bin

### OS X: Macports

    sudo port install advancecomp gifsicle jhead jpegoptim jpeg optipng pngcrush

### OS X: Brew

    brew install advancecomp gifsicle jhead jpegoptim jpeg optipng pngcrush

### pngout installation (optional)

You can install `pngout` by downloading and installing the [binary versions](http://www.jonof.id.au/kenutils).

_Note: pngout is free to use even in commercial soft, but you can not redistribute, repackage or reuse it without consent and agreement of creator. [license](http://advsys.net/ken/utils.htm#pngoutkziplicense)_

## Usage

### From shell

    image_optim *.{jpg,png,gif}

    image_optim -h

### From ruby

Initilize optimizer:

    image_optim = ImageOptim.new

    image_optim = ImageOptim.new(:pngout => false)

    image_optim = ImageOptim.new(:nice => 20)

Optimize image getting temp path:

    image_optim.optimize_image('a.png')

Optimize image in place:

    image_optim.optimize_image!('b.jpg')

Multiple images:

    image_optim.optimize_images(Dir['*.png']) do |unoptimized, optimized|
      if optimized
        puts "#{unoptimized} => #{optimized}"
      end
    end

    image_optim.optimize_images!(Dir['*.*'])

### From rails

`ImageOptim::Railtie` will automatically initialize processing of assets if `config.assets.compress` is true.

As image optimization can be time consuming you may prefer to optimize original asset files.

Automatic assets processing can be turned off by setting `config.assets.image_optim = false`.

## Configuration

Configuration in YAML format will be read and prepanded to options from two paths:

* `$XDG_CONFIG_HOME/image_optim.yml` (by default `~/.config/image_optim.yml`)
* `.image_optim.yml` in current working directory

Example configuration:

    nice: 20
    pngout: false # disable
    optipng:
      level: 5

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

Copyright (c) 2012-2013 Ivan Kuchin. See LICENSE.txt for details.
