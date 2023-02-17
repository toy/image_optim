[![Gem Version](https://img.shields.io/gem/v/image_optim?logo=rubygems)](https://rubygems.org/gems/image_optim)
[![Build Status](https://img.shields.io/github/actions/workflow/status/toy/image_optim/check.yml?logo=github)](https://github.com/toy/image_optim/actions/workflows/check.yml)
[![Rubocop](https://img.shields.io/github/actions/workflow/status/toy/image_optim/rubocop.yml?label=rubocop&logo=rubocop)](https://github.com/toy/image_optim/actions/workflows/rubocop.yml)
[![CodeQL](https://img.shields.io/github/actions/workflow/status/toy/image_optim/codeql.yml?label=codeql&logo=github)](https://github.com/toy/image_optim/actions/workflows/codeql.yml)
[![Code Climate](https://img.shields.io/codeclimate/maintainability/toy/image_optim?logo=codeclimate)](https://codeclimate.com/github/toy/image_optim)
[![Code Climate Coverage](https://img.shields.io/codeclimate/coverage/toy/image_optim?logo=codeclimate)](https://codeclimate.com/github/toy/image_optim)
[![Depfu](https://img.shields.io/depfu/toy/image_optim)](https://depfu.com/github/toy/image_optim)
[![Inch CI](https://inch-ci.org/github/toy/image_optim.svg?branch=master)](https://inch-ci.org/github/toy/image_optim)

# image_optim

Command line tool and ruby interface to optimize (lossless compress, optionally lossy) jpeg, png, gif and svg images using external utilities:

* [advpng](http://advancemame.sourceforge.net/doc-advpng.html) from [AdvanceCOMP](http://advancemame.sourceforge.net/comp-readme.html)
(will use [zopfli](https://code.google.com/p/zopfli/) on default/maximum level 4)
* [gifsicle](http://www.lcdf.org/gifsicle/)
* [jhead](http://www.sentex.net/~mwandel/jhead/)
* [jpegoptim](http://www.kokkonen.net/tjko/projects.html)
* [jpeg-recompress](https://github.com/danielgtaylor/jpeg-archive#jpeg-recompress)
* jpegtran from [Independent JPEG Group's JPEG library](http://www.ijg.org/)
* [optipng](http://optipng.sourceforge.net/)
* [oxipng](https://github.com/shssoichiro/oxipng)
* [pngcrush](http://pmt.sourceforge.net/pngcrush/)
* [pngout](http://www.advsys.net/ken/util/pngout.htm)
* [pngquant](http://pngquant.org/)
* [svgo](https://github.com/svg/svgo)

Based on [ImageOptim.app](http://imageoptim.com/).

Documentation for [latest gem version](http://rubydoc.info/gems/image_optim/frames) and [master branch](http://rubydoc.info/github/toy/image_optim/master/frames).

A test application with latest `image_optim` and `image_optim_pack` is available on render: https://iopack.onrender.com/.

## Gem installation

```sh
gem install image_optim
```

You may also want to install [`image_optim_pack`](https://github.com/toy/image_optim_pack) (see [Binaries pack](#binaries-pack)).

```sh
gem install image_optim_pack
```

### Bundler

Add to your `Gemfile`:

```ruby
gem 'image_optim'
```

With `image_optim_pack`:

```ruby
gem 'image_optim'
gem 'image_optim_pack'
```

With version:

<!---<update-version>-->
```ruby
gem 'image_optim', '~> 0.31'
```
<!---</update-version>-->

If you want to check latest changes:

```ruby
gem 'image_optim', :git => 'git://github.com/toy/image_optim.git'
```

## Docker

This gem is also be available as [docker image](https://github.com/toy/image_optim_pack/pkgs/container/image_optim) containing most binaries:

```bash
docker run --rm ghcr.io/toy/image_optim --version # image_optim version
docker run --rm ghcr.io/toy/image_optim --info # image_optim info including bin versions
docker run --rm -v "$PWD":/here -w /here ghcr.io/toy/image_optim image-in-this-folder.jpg
```

See [image_optim_pack repository](https://github.com/toy/image_optim_pack) for [Dockerfile](https://github.com/toy/image_optim_pack/blob/master/Dockerfile) and [instructions](https://github.com/toy/image_optim_pack#docker).

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

### Binaries pack

Easiest way to get latest versions of most binaries for `image_optim` for Linux and Mac OS X is by installing [`image_optim_pack`](https://github.com/toy/image_optim_pack) gem.

Check installation instructions in [Gem installation](#gem-installation) section.

Pack doesn't include `pngout` and `svgo` binaries, their installation instructions are provided below.

### Linux - Debian/Ubuntu

```bash
sudo apt-get install -y advancecomp gifsicle jhead jpegoptim libjpeg-progs optipng pngcrush pngquant
```

If you get an old version of `pngquant`, please check how to install up-to-date version or compile from source at [http://pngquant.org/](http://pngquant.org/).

### Linux - RHEL/Fedora/Centos

```bash
sudo yum install -y advancecomp gifsicle jhead libjpeg optipng pngquant
```

You may also need to install `libjpeg-turbo-utils` instead of `libjpeg`:

```bash
sudo yum install -y libjpeg-turbo-utils
```

You will also need to install `jpegoptim` and `pngcrush` from source:

#### jpegoptim

Replace `X.Y.Z` with latest version number from http://www.kokkonen.net/tjko/projects.html#jpegoptim.

```bash
JPEGOPTIM_VERSION=X.Y.Z
cd /tmp
curl -O http://www.kokkonen.net/tjko/src/jpegoptim-$JPEGOPTIM_VERSION.tar.gz
tar zxf jpegoptim-$JPEGOPTIM_VERSION.tar.gz
cd jpegoptim-$JPEGOPTIM_VERSION
./configure && make && make install
```

#### pngcrush

Replace `X.Y.Z` with latest version number from http://sourceforge.net/projects/pmt/files/pngcrush/.

```bash
PNGCRUSH_VERSION=X.Y.Z
cd /tmp
curl -O http://iweb.dl.sourceforge.net/project/pmt/pngcrush/$PNGCRUSH_VERSION/pngcrush-$PNGCRUSH_VERSION.tar.gz
tar zxf pngcrush-$PNGCRUSH_VERSION.tar.gz
cd pngcrush-$PNGCRUSH_VERSION
make && cp -f pngcrush /usr/local/bin
```

### OS X: Macports

```bash
sudo port install advancecomp gifsicle jhead jpegoptim jpeg optipng pngcrush pngquant
```

### OS X: Brew

```bash
brew install advancecomp gifsicle jhead jpegoptim jpeg optipng oxipng pngcrush pngquant jonof/kenutils/pngout
```

### oxipng installation (optional)

Unless it is available in your chosen package manager, can be installed using cargo:

```bash
cargo install oxipng
```

### pngout installation (optional)

If you installed the dependencies via brew, pngout should be installed already. Otherwise, you can install `pngout` by downloading and installing the [binary versions](http://www.jonof.id.au/kenutils).

_Note: pngout is free to use even in commercial soft, but you can not redistribute, repackage or reuse it without consent and agreement of creator. [license](http://advsys.net/ken/utils.htm#pngoutkziplicense)_

### svgo installation (optional)

`svgo` is available from NPM.

```bash
npm install -g svgo
```

If you prefer to install `svgo` to your project directory, use one of the following commands instead:

```bash
npm install svgo

yarn add svgo
```

When installing `svgo` to the project directory, you must add the following to your environment:

```
SVGO_BIN='node_modules/svgo/bin/svgo'
```

### jpeg-recompress installation (optional)

Download and install the `jpeg-recompress` binary from the [JPEG-Archive Releases](https://github.com/danielgtaylor/jpeg-archive/releases) page,
or follow the instructions to [build from source](https://github.com/danielgtaylor/jpeg-archive#building).

## Usage

### From shell

```sh
image_optim *.{jpg,png,gif,svg}

image_optim -r .

image_optim -h
```

### From ruby

Initialize optimizer (or you can call optimization methods directly on `ImageOptim`):

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

Rails image assets optimization is extracted into [image\_optim\_rails gem](https://github.com/toy/image_optim_rails).

## Configuration

Configuration in YAML format will be read and prepended to options from two paths:

* `$XDG_CONFIG_HOME/image_optim.yml` (by default `~/.config/image_optim.yml`)
* `.image_optim.yml` in current working directory

Paths can be changed using `:config_paths` option and `--config-paths` argument.

Example configuration:

```yaml
nice: 20
pngout: false # disable
optipng:
  level: 5
```

### Temporary directory

`image_optim` uses standard ruby library for creating temporary files. Temporary directory can be changed using one of `TMPDIR`, `TMP` or `TEMP` environment variables.

## Options

* `:nice` — Nice level, priority of all used tools with higher value meaning lower priority, in range `-20..19`, negative values can be set only if run by root user *(defaults to `10`)*
* `:threads` — Number of threads or disable *(defaults to number of processors)*
* `:verbose` — Verbose output *(defaults to `false`)*
* `:pack` — Require image\_optim\_pack or disable it, by default image\_optim\_pack will be used if available, will turn on `:skip-missing-workers` unless explicitly disabled *(defaults to `nil`)*
* `:skip_missing_workers` — Skip workers with missing or problematic binaries *(defaults to `false`)*
* `:allow_lossy` — Allow lossy workers and optimizations *(defaults to `false`)*
* `:cache_dir` — Configure cache directory
* `:cache_worker_digests` - Also cache worker digests along with original file digest and worker options: updating workers invalidates cache
* `:timeout` — Maximum time in seconds to spend on one image, note multithreading and cache *(defaults to unlimited)*

Worker can be disabled by passing `false` instead of options hash or by setting option `:disable` to `true`.

<!---<worker-options>-->
<!-- markdown for worker options is generated by `script/update_worker_options_in_readme` -->

### advpng:
* `:level` — Compression level: `0` - don't compress, `1` - fast, `2` - normal, `3` - extra, `4` - extreme *(defaults to `4`)*

### gifsicle:
* `:interlace` — Interlace: `true` - interlace on, `false` - interlace off, `nil` - as is in original image (defaults to running two instances, one with interlace off and one with on)
* `:level` — Compression level: `1` - light and fast, `2` - normal, `3` - heavy (slower) *(defaults to `3`)*
* `:careful` — Avoid bugs with some software *(defaults to `false`)*

### jhead:
Worker has no options

### jpegoptim:
* `:allow_lossy` — Allow limiting maximum quality *(defaults to `false`)*
* `:strip` — List of markers to strip: `:com`, `:exif`, `:iptc`, `:icc`, `:xmp`, `:none` or `:all` *(defaults to `:all`)*
* `:max_quality` — Maximum image quality factor `0`..`100`, ignored in default/lossless mode *(defaults to `100`)*

### jpegrecompress:
* `:allow_lossy` — Allow worker, it is always lossy *(defaults to `false`)*
* `:quality` — JPEG quality preset: `0` - low, `1` - medium, `2` - high, `3` - veryhigh *(defaults to `3`)*
* `:method` — Comparison Metric: `mpe` - Mean pixel error, `ssim` - Structural similarity, `ms-ssim` - Multi-scale structural similarity (slow!), `smallfry` - Linear-weighted BBCQ-like (may be patented) *(defaults to ssim)*

### jpegtran:
* `:copy_chunks` — Copy all chunks *(defaults to `false`)*
* `:progressive` — Create progressive JPEG file *(defaults to `true`)*
* `:jpegrescan` — Use jpegtran through jpegrescan, ignore progressive option *(defaults to `true`)*

### optipng:
* `:level` — Optimization level preset: `0` is least, `7` is best *(defaults to `6`)*
* `:interlace` — Interlace: `true` - interlace on, `false` - interlace off, `nil` - as is in original image *(defaults to `false`)*
* `:strip` — Remove all auxiliary chunks *(defaults to `true`)*

### oxipng:
* `:level` — Optimization level preset: `0` is least, `6` is best *(defaults to `3`)*
* `:interlace` — Interlace: `true` - interlace on, `false` - interlace off, `nil` - as is in original image *(defaults to `false`)*
* `:strip` — Remove all auxiliary chunks *(defaults to `true`)*

### pngcrush:
* `:chunks` — List of chunks to remove or `:alla` - all except tRNS/transparency or `:allb` - all except tRNS and gAMA/gamma *(defaults to `:alla`)*
* `:fix` — Fix otherwise fatal conditions such as bad CRCs *(defaults to `false`)*
* `:brute` — Brute force try all methods, very time-consuming and generally not worthwhile *(defaults to `false`)*
* `:blacken` — Blacken fully transparent pixels *(defaults to `true`)*

### pngout:
* `:copy_chunks` — Copy optional chunks *(defaults to `false`)*
* `:strategy` — Strategy: `0` - xtreme, `1` - intense, `2` - longest Match, `3` - huffman Only, `4` - uncompressed *(defaults to `0`)*

### pngquant:
* `:allow_lossy` — Allow quality option *(defaults to `false`)*
* `:max_colors` — Maximum number of colors to use *(defaults to `256`)*
* `:quality` — min..max - don't save below min, use less colors below max (both in range `0..100`; in yaml - `!ruby/range 0..100`), ignored in default/lossless mode *(defaults to `100..100`, `0..100` in lossy mode)*
* `:speed` — speed/quality trade-off: `1` - slow, `3` - default, `11` - fast & rough *(defaults to `3`)*

### svgo:
* `:disable_plugins` — List of plugins to disable *(defaults to `[]`)*
* `:enable_plugins` — List of plugins to enable *(defaults to `[]`)*

<!---</worker-options>-->

## Contributing

[List](https://github.com/toy/image_optim/graphs/contributors) of contributors to `image_optim`.

If you would like to contribute - that is great and you are very welcome. Please check few notes in file [CONTRIBUTING.markdown](CONTRIBUTING.markdown).

## ChangeLog

In separate file [CHANGELOG.markdown](CHANGELOG.markdown).

## Copyright

Copyright (c) 2012-2023 Ivan Kuchin. See [LICENSE.txt](LICENSE.txt) for details.
