# image_optim

Optimize (lossless compress) images (jpeg, png, gif) using external utilities (advpng, gifsicle, jpegoptim, jpegtran, optipng, pngcrush, pngout).

Based on [ImageOptim.app](http://imageoptim.pornel.net/).

## Gem Installation

    gem install image_optim

## Binaries Installation

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
    curl -O http://iweb.dl.sourceforge.net/project/pmt/pngcrush/1.7.24/pngcrush-1.7.24.tar.bz2
    tar jxf pngcrush-1.7.24.tar.bz2
    cd pngcrush-1.7.24
    make && cp -f pngcrush /usr/local/bin

### OS X - Macports

    sudo port install advancecomp gifsicle jpegoptim jpeg optipng pngcrush

### OS X - Brew

    brew install advancecomp gifsicle jpegoptim jpeg optipng pngcrush

## pngout Installation (optional)

You can install `pngout` by downloading and installing the [binary versions](http://www.jonof.id.au/kenutils).

_Note: pngout is free to use even in commercial soft, but you can not redistribute, repackage or reuse it without consent and agreement of creator. [license](http://advsys.net/ken/utils.htm#pngoutkziplicense)_

## Usage

In terminal:

    image_optim *.{jpg,png,gif}

    image_optim -h

Initilize optimizer (options are described in comments for ImageOptim, Worker and all workers):

    io = ImageOptim.new

    io = ImageOptim.new(:pngout => false)

    io = ImageOptim.new(:nice => 20)

Optimize image getting temp path:

    io.optimize_image('a.png')

Optimize image in place:

    io.optimize_image!('b.jpg')

Multiple images:

    io.optimize_images(Dir['*.png']) do |unoptimized, optimized|
      if optimized
        puts "#{unoptimized} => #{optimized}"
      end
    end

    io.optimize_images!(Dir['*.*'])

## Copyright

Copyright (c) 2012 Ivan Kuchin. See LICENSE.txt for details.
