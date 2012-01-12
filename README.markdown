# image_optim

Optimize images (jpeg, png, gif) using external utilities (advpng, gifsicle, jpegoptim, jpegtran, optipng, pngcrush, pngout).

Based on [ImageOptim.app](http://imageoptim.pornel.net/).

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

    io.optimize_image('b.jpg')

Multiple images:

    io.optimize_images(Dir['*.png']) do |unoptimized, optimized|
      if optimized
        puts "#{unoptimized} => #{optimized}"
      end
    end

    io.optimize_images!(Dir['*.*'])

## Copyright

Copyright (c) 2012 Ivan Kuchin. See LICENSE.txt for details.
