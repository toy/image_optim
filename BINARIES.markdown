# How to install `advpng`, `gifsicle`, `jpegoptim`, `jpegtran`, `optipng`, `pngcrush`, `pngout`*

## Linux - Debian/Ubuntu

    sudo apt-get install -y advancecomp gifsicle jpegoptim libjpeg-progs optipng pngcrush

## Linux - RHEL/Fedora/Centos

    sudo yum install -y advancecomp gifsicle libjpeg optipng
    
You will also need to build install `jpegoptim` and `pngcrush` by hand (see below).

## OS X - Macports

    sudo port install advancecomp gifsicle jpegoptim jpeg optipng pngcrush

## OS X - Brew

    brew install advancecomp gifsicle jpegoptim jpeg optipng pngcrush

## Build and install `jpegoptim`

    cd /tmp
    curl -O http://www.kokkonen.net/tjko/src/jpegoptim-1.2.4.tar.gz
    tar zxf jpegoptim-1.2.4.tar.gz
    cd jpegoptim-1.2.4
    ./configure && make && make install

## Build and install `pngcrush`

    cd /tmp
    curl -O http://iweb.dl.sourceforge.net/project/pmt/pngcrush/1.7.24/pngcrush-1.7.24.tar.bz2
    tar jxf pngcrush-1.7.24.tar.bz2
    cd pngcrush-1.7.24
    make && cp -f pngcrush /usr/local/bin

## * - `pngout`

`pngout` is not free or open source software and only has [binary versions](http://www.jonof.id.au/kenutils) available.

_Note: pngout is not required to use `image_optim`._

- 
