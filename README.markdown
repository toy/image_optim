# image_optim

Optimize (lossless compress) images (jpeg, png, gif) using external utilities:

* [advpng](http://advancemame.sourceforge.net/doc-advpng.html) from [AdvanceCOMP](http://advancemame.sourceforge.net/comp-readme.html)
* [gifsicle](http://www.lcdf.org/gifsicle/)
* [jpegoptim](http://www.kokkonen.net/tjko/projects.html)
* jpegtran from [Independent JPEG Group's JPEG library](http://www.ijg.org/)
* [optipng](http://optipng.sourceforge.net/)
* [pngcrush](http://pmt.sourceforge.net/pngcrush/)
* [pngout](http://www.advsys.net/ken/util/pngout.htm)

Based on [ImageOptim.app](http://imageoptim.com/).

## Gem installation

    gem install image_optim

## Binaries location

Simplest way for `image_optim` to locate binaries is to install them in common location present in `PATH` (see [Binaries installation](#binaries-installation)).

If you cannot install to common location, then install to custom one and add it to `PATH`.

Specify custom bin location using `XXX_BIN` environment variable (`JPEGOPTIM_BIN`, `OPTIPNG_BIN`, …).

Besides permanently setting environment variables in `~/.profile`, `~/.bash_profile`, `~/.bashrc`, `~/.zshrc`, … they can be set:

* before command: `PATH="/custom/location:$PATH" image_optim *.jpg`

* inside script: `ENV['PATH'] = "/custom/location:#{ENV['PATH']}"; ImageOptim.optimize_images([…])`

## Binaries installation

### Linux - Debian/Ubuntu

    sudo apt-get install -y advancecomp gifsicle jpegoptim libjpeg-progs optipng pngcrush

### Linux - RHEL/Fedora/Centos

    sudo yum install -y advancecomp gifsicle libjpeg optipng

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

    sudo port install advancecomp gifsicle jpegoptim jpeg optipng pngcrush

### OS X: Brew

    brew install advancecomp gifsicle jpegoptim jpeg optipng pngcrush

### pngout installation (optional)

You can install `pngout` by downloading and installing the [binary versions](http://www.jonof.id.au/kenutils).

_Note: pngout is free to use even in commercial soft, but you can not redistribute, repackage or reuse it without consent and agreement of creator. [license](http://advsys.net/ken/utils.htm#pngoutkziplicense)_

## Usage

### From shell

    image_optim *.{jpg,png,gif}

    image_optim -h

### From ruby

Initilize optimizer (options are described in comments for ImageOptim, Worker and all workers):

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

## Copyright

Copyright (c) 2012 Ivan Kuchin. See LICENSE.txt for details.
