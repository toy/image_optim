# ChangeLog

## unreleased

## v0.26.4 (2019-05-23)

* Enable frozen string literals [@toy](https://github.com/toy)

## v0.26.3 (2018-10-13)

* Handle `vnone` version of `advpng` that was erroneously produced for `ubuntu` and `homebrew` [#165](https://github.com/toy/image_optim/issues/165) [@toy](https://github.com/toy)

## v0.26.2 (2018-08-15)

* Ignore segmentation fault for `pngout` <= `20150920` [#158](https://github.com/toy/image_optim/issues/158) [@toy](https://github.com/toy)
* Allow `image_size` 2.x [@toy](https://github.com/toy)
* Add instructions for installing `svgo` in project folder [#156](https://github.com/toy/image_optim/issues/156) [@brian-kephart](https://github.com/brian-kephart)
* Show full bin search path in verbose output [@toy](https://github.com/toy)

## v0.26.1 (2017-12-14)

* Require `'date'` which is used in parsing pngout version [toy/image_optim_pack#14](https://github.com/toy/image_optim_pack/issues/14) [@toy](https://github.com/toy)

## v0.26.0 (2017-11-13)

* Enable `jpegrescan` by default after removing its dependency on `File::Slurp` and fixing for windows [#153](https://github.com/toy/image_optim/issues/153) [@toy](https://github.com/toy)
* Extend description of `--verbose` flag [#152](https://github.com/toy/image_optim/issues/152) [@toy](https://github.com/toy)

## v0.25.0 (2017-07-06)

* Fix error `uninitialized constant EXIFR::JPEG` (breaking change in [exifr v1.3.0](https://github.com/remvee/exifr/commit/e073a22d06c39f2c1c0e77f5b5fe71545b25e967)) [#150](https://github.com/toy/image_optim/pull/150) [@abemedia](https://github.com/abemedia)
* Add option to `pngquant` worker to limit maximum number of colors to use [#144](https://github.com/toy/image_optim/issues/144) [@toy](https://github.com/toy)

## v0.24.3 (2017-05-04)

* Set mode of cache files to `0666 & ~umask`, related to [#147](https://github.com/toy/image_optim/issues/147) [@toy](https://github.com/toy)

## v0.24.2 (2017-02-18)

* Describe `nice` level option [#140](https://github.com/toy/image_optim/issues/140) [@toy](https://github.com/toy)
* Add instruction for installing `pngout` using brew [#143](https://github.com/toy/image_optim/pull/143) [@lukaselmer](https://github.com/lukaselmer)

## v0.24.1 (2016-11-20)

* Use `image_size ~> 1.5` with `apng` detection, so apng images are not optimised to one frame version [#142](https://github.com/toy/image_optim/issues/142) [@toy](https://github.com/toy)
* Don't show `?` for unknown bin version in message about inability to determine version [@toy](https://github.com/toy)
* Deduplicate bin resolving error messages [@toy](https://github.com/toy)

## v0.24.0 (2016-08-14)

* Rails image assets optimization is extracted into [image\_optim\_rails gem](https://github.com/toy/image_optim_rails) [#127](https://github.com/toy/image_optim/issues/127) [@toy](https://github.com/toy)
* Add proper handling of `ImageOptim.respond_to?` [@toy](https://github.com/toy)
* Fix an issue not working OptiPNG `interlace` option [#136](https://github.com/toy/image_optim/pull/136) [@mrk21](https://github.com/mrk21)
* Minimize number of file system calls in default implementation of `optimized?` [#137](https://github.com/toy/image_optim/issues/137) [@toy](https://github.com/toy)

## v0.23.0 (2016-07-17)

* Added `cache_dir` and `cache_worker_digests` options to cache results [#83](https://github.com/toy/image_optim/issues/83) [@gpakosz](https://github.com/gpakosz)
* Should work on windows [#24](https://github.com/toy/image_optim/issues/24) [@toy](https://github.com/toy)
* Rename `ImageOptim::ImagePath` to `ImageOptim::Path` and its method `#format` to `#image_format` [@toy](https://github.com/toy)
* Ignore empty config files [#133](https://github.com/toy/image_optim/issues/133) [@toy](https://github.com/toy)
* Use `FileUtils.move` in `ImagePath#replace` to rename file instead of copying on same device, don't preserve mtime and atime [#134](https://github.com/toy/image_optim/issues/134) [@toy](https://github.com/toy)
* Make `:allow_lossy` an individual option for workers that can use it, so it will be in the list of worker options [#130](https://github.com/toy/image_optim/issues/130) [@toy](https://github.com/toy)
* Use first 8 characters of sha1 hex for jpegrescan version [#131](https://github.com/toy/image_optim/issues/131) [@toy](https://github.com/toy)

## v0.22.1 (2016-02-21)

* Fix missing old (1.x) `pngquant` version as it was output to stderr [#123](https://github.com/toy/image_optim/issues/123) [@toy](https://github.com/toy)
* Fix capturing wrong version of `pngcrush` when it complains about different png.h and png.c [#122](https://github.com/toy/image_optim/issues/122) [@toy](https://github.com/toy)
* Add support for `sprockets-rails` 3.x, kudos to [@iggant](https://github.com/iggant) and [@valff](https://github.com/valff) for initial PRs [#120](https://github.com/toy/image_optim/pull/120) [#121](https://github.com/toy/image_optim/pull/121) [#126](https://github.com/toy/image_optim/pull/126) [@toy](https://github.com/toy)
* Use rubocop ~> 0.37 [@toy](https://github.com/toy)

## v0.22.0 (2015-11-21)

* Unify getting description of option default value using `default_description` [@toy](https://github.com/toy)
* Don't use `-strip` option for optipng when the bin version is less than 0.7 [#106](https://github.com/toy/image_optim/issues/106) [@toy](https://github.com/toy)
* Use quality `0..100` by default in lossy mode of pngquant worker [#77](https://github.com/toy/image_optim/issues/77) [@toy](https://github.com/toy)
* Add `:disable_plugins` and `:enable_plugins` options to `svgo` worker [#110](https://github.com/toy/image_optim/pull/110) [@tomhughes](https://github.com/tomhughes)
* Allow setting config in rails like `config.assets.image_optim.name = value` [#111](https://github.com/toy/image_optim/pull/111) [@toy](https://github.com/toy)

## v0.21.0 (2015-05-30)

* Use exifr 1.2.2 with fix for a bug [#85](https://github.com/toy/image_optim/issues/85) [@toy](https://github.com/toy)
* Change order of png workers according to analysis to pngcrush, optipng, pngquant, pngout, advpng (was pngquant, pngcrush, pngout, advpng, optipng) [@toy](https://github.com/toy)
* Run worker command without invoking shell (except ruby < 1.9 and jruby) [@toy](https://github.com/toy)
* Add disabling worker by passing `:disable => true` (previously only by passing `false` instead of options hash) [@toy](https://github.com/toy)
* Add tests for railtie, also to prevent [issues like #72](https://github.com/toy/image_optim/issues/72) [#73](https://github.com/toy/image_optim/issues/73) [@toy](https://github.com/toy)
* Remove haml development dependency [@toy](https://github.com/toy)
* Add `-strip` option to optipng worker to remove all metadata chunks, on by default [#75](https://github.com/toy/image_optim/issues/75) [@jwidderich](https://github.com/jwidderich)
* Fixing minor spelling mistakes from `--help` output [#79](https://github.com/toy/image_optim/issues/79) [@kaspergrubbe](https://github.com/kaspergrubbe)

## v0.20.2 (2014-12-26)

* Fix `ImagePath#temp_path` for ruby 2.2 caused by `Tmpname#make_tmpname` accepting only objects directly convertible to String for prefix and suffix starting with 2.2 [#74](https://github.com/toy/image_optim/issues/74) [@toy](https://github.com/toy)

## v0.20.1 (2014-12-19)

* Fix [paperclip-optimizer issue #13](https://github.com/janfoeh/paperclip-optimizer/issues/13): railtie broken with `undefined local variable or method 'app'` [#72](https://github.com/toy/image_optim/issues/72) [@janfoeh](https://github.com/janfoeh)

## v0.20.0 (2014-12-15)

* Ignore and show warning for lossy options `jpegoptim#max_quality` and `pngquant#quality` in default/lossless mode [#71](https://github.com/toy/image_optim/issues/71) [@toy](https://github.com/toy)
* Add `:blacken` option to `pngcrush` worker, to blacken fully transparent pixels, on by default [@toy](https://github.com/toy)
* Command line option `--no-progress` to disable showing progress of optimizing images [@toy](https://github.com/toy)

## v0.19.1 (2014-11-22)

* Blacklist pngcrush 1.7.80 as it loses one color in indexed images [@toy](https://github.com/toy)

## v0.19.0 (2014-11-08)

* Added lossy worker `jpegrecompress` (uses [`jpeg-recompress`](https://github.com/danielgtaylor/jpeg-archive#jpeg-recompress)), disabled unless `:allow_lossy` is true [#65](https://github.com/toy/image_optim/issues/65) [@wjordan](https://github.com/wjordan) [@toy](https://github.com/toy)
* `:allow_lossy` option to allow lossy workers and optimizations [@toy](https://github.com/toy)
* Don't warn multiple times about problematic binary [#69](https://github.com/toy/image_optim/issues/69) [@toy](https://github.com/toy)
* Run gisicle two times (with interlace off then with on) if interlace is not set explicitly [#70](https://github.com/toy/image_optim/issues/70) [@toy](https://github.com/toy)
* Remove app and other extensions from gif images [@toy](https://github.com/toy)
* Change behaviour of gifsicle interlace option to deinterlace for `false`, pass `nil` to leave as is [@toy](https://github.com/toy)
* Worker can change its initialization by overriding `init` and can initialize multiple instances [#70](https://github.com/toy/image_optim/issues/70) [@toy](https://github.com/toy)

## v0.18.0 (2014-11-01)

* Add interface to `image_optim_pack` [@toy](https://github.com/toy)
* Use `in_threads ~> 1.3` [@toy](https://github.com/toy)
* Added options to Gifsicle, specifically --careful (for compatibility) and --optimize for granularity [#51](https://github.com/toy/image_optim/issues/51) [@kaspergrubbe](https://github.com/kaspergrubbe)
* `:skip_missing_workers` option to skip workers with missing or problematic binaries [#66](https://github.com/toy/image_optim/issues/66) [@toy](https://github.com/toy)
* Speedup specs (~8x) [#60](https://github.com/toy/image_optim/issues/60) [@toy](https://github.com/toy)
* `script/worker_analysis` to compare worker chains by optimization, time and losslessness [@toy](https://github.com/toy)
* `Cmd` module to ensure interrupted commands can't go unnoticed [@toy](https://github.com/toy)

## v0.17.1 (2014-10-06)

* Fix bin path resolving method missing vendor directory [@toy](https://github.com/toy)

## v0.17.0 (2014-10-04)

* Use pure ruby detection of bin path [@toy](https://github.com/toy)
* Fail if version of bin can't be detected [#39](https://github.com/toy/image_optim/issues/39) [@toy](https://github.com/toy)
* Check path in `XXX_BIN` to exist, be a file and be executable [@toy](https://github.com/toy)
* `image_optim --info` to perform initialization with verbose output without running optimizations [@toy](https://github.com/toy)
* Changeable config paths [@toy](https://github.com/toy)

## v0.16.0 (2014-09-12)

* Wrote this ChangeLog [#62](https://github.com/toy/image_optim/issues/62) [@toy](https://github.com/toy)
* Use rubocop ~> 0.26.0 [@toy](https://github.com/toy)
* Install advancecomp from source in travis script [#61](https://github.com/toy/image_optim/issues/61) [@toy](https://github.com/toy)
* Move expansion of config path to read method and rescue with warning [#58](https://github.com/toy/image_optim/issues/58) [@toy](https://github.com/toy)
* Show workers options in verbose mode [#56](https://github.com/toy/image_optim/issues/56) [@toy](https://github.com/toy)
* Resolve all bins during initialization [#22](https://github.com/toy/image_optim/issues/22) [@toy](https://github.com/toy)
* Add exclusion glob patterns, `.*` by default [#35](https://github.com/toy/image_optim/issues/35) [#48](https://github.com/toy/image_optim/issues/48) [@toy](https://github.com/toy)
* Show better warning when running image_optim for a directory without recursive option [@toy](https://github.com/toy)
* Use stable sort for workers [@toy](https://github.com/toy)
* Check binary version instead of using which to check if binary is present [#59](https://github.com/toy/image_optim/issues/59) [@toy](https://github.com/toy)

## v0.15.0 (2014-08-19)

* Use advpng worker before optipng [@toy](https://github.com/toy)
* Fix order of results (use progress ~> 3.0.1) [@toy](https://github.com/toy)
* Change array returned from `optimize_images`, `optimize_images!` and `optimize_images_data` to contain pairs of item and result instead of just result [@toy](https://github.com/toy)
* Fixed `Space` causing exception with negative numbers [@toy](https://github.com/toy)
* Added pngquant worker [#14](https://github.com/toy/image_optim/issues/14) [#32](https://github.com/toy/image_optim/issues/32) [#40](https://github.com/toy/image_optim/issues/40) [#52](https://github.com/toy/image_optim/issues/52) [@adammathys](https://github.com/adammathys) [@smasry](https://github.com/smasry) [@toy](https://github.com/toy)
* Add instructions to errors from bin resolver [@toy](https://github.com/toy)
* Use in_threads ~> 1.2.2 with fix for silent exceptions [@toy](https://github.com/toy)
* Fix `LocalJumpError` in railtie initializer block (ruby 2.1.2, rails 4.1.4) [#50](https://github.com/toy/image_optim/issues/50) [@schnittchen](https://github.com/schnittchen)

## v0.14.0 (2014-07-17)

* Added Inch CI and Gittip badges to README [@toy](https://github.com/toy)
* Assign worker options to constants for documentation [@toy](https://github.com/toy)
* Code style, reorganized, comments, added rubocop [@toy](https://github.com/toy)
* Switch to rspec 3.0 [@toy](https://github.com/toy)
* Don't mention versions in instructions for installing jpegoptim and pngcrush [@toy](https://github.com/toy)

## v0.13.3 (2014-05-22)

* Added instruction about libjpeg-turbo-utils [#49](https://github.com/toy/image_optim/issues/49) [@toy](https://github.com/toy)

## v0.13.2 (2014-04-24)

* Updated versions of `pngcrush` and `jpegoptim` in installation instructions [#46](https://github.com/toy/image_optim/issues/46) [@toy](https://github.com/toy)
* Script for updating instructions in README [@toy](https://github.com/toy)
* Typo in README [#45](https://github.com/toy/image_optim/issues/45) [@rawsyntax](https://github.com/rawsyntax)

## v0.13.1 (2014-04-08)

* Use image_size ~> 1.3.0 so only `FormatError` exceptions are caught and show warning [#44](https://github.com/toy/image_optim/issues/44) [@lencioni](https://github.com/lencioni)

## v0.13.0 (2014-04-06)

* Detect and warn about broken images [#43](https://github.com/toy/image_optim/issues/43) [@toy](https://github.com/toy)
* Output image_optim version when running in verbose mode [@toy](https://github.com/toy)
* Show resolved version in version exceptions and warnings [@toy](https://github.com/toy)
* Warn if advpng version is less than 1.17 as it does not use zopfli [#17](https://github.com/toy/image_optim/issues/17) [#18](https://github.com/toy/image_optim/issues/18) [@toy](https://github.com/toy)

## v0.12.1 (2014-03-10)

* Don't try to register preprocessors when sprockets library is not initialized (app.assets is nil) [#41](https://github.com/toy/image_optim/issues/41) [@toy](https://github.com/toy)
* Output resolved binaries when verbose [@toy](https://github.com/toy)
* Output nice level and number of threads when verbose [@toy](https://github.com/toy)
* Output config to stderr when verbose [@toy](https://github.com/toy)
* Don't limit number of threads [@toy](https://github.com/toy)

## v0.12.0 (2014-03-02)

* Checking bin versions [#33](https://github.com/toy/image_optim/issues/33) [@toy](https://github.com/toy)

## v0.11.2 (2014-03-01)

* Fixed building PATH environment variable [@toy](https://github.com/toy)

## v0.11.1 (2014-02-20)

* Allow `-v` for version if it is the only argument [@toy](https://github.com/toy)
* Fixed initializing railtie [#37](https://github.com/toy/image_optim/issues/37) [@toy](https://github.com/toy)

## v0.11.0 (2014-02-16)

* Use image_size ~> 1.2.0 [@toy](https://github.com/toy)
* Added `svgo` worker and support for svg files [#27](https://github.com/toy/image_optim/issues/27) [#30](https://github.com/toy/image_optim/issues/30) [@nybblr](https://github.com/nybblr)
* Properly unlink temporary files [#29](https://github.com/toy/image_optim/issues/29) [@toy](https://github.com/toy)
* Read options from rails app configuration `app.config.assets.image_optim` in railtie [#31](https://github.com/toy/image_optim/issues/31) [@bencrouse](https://github.com/bencrouse)
* Updated versions of `pngcrush` and `jpegoptim` in installation instructions [#26](https://github.com/toy/image_optim/issues/26) [@jc00ke](https://github.com/jc00ke)

## v0.10.2 (2014-01-25)

* Fixed regression with progress introduced in v0.10.0 [@toy](https://github.com/toy)

## v0.10.1 (2014-01-23)

* Ensure binary data (ruby 1.9+) from `optimize_image_data` and `optimize_images_data` [#25](https://github.com/toy/image_optim/issues/25) [@toy](https://github.com/toy)
* Mention `optimize_image_data` and `optimize_images_data` in README [#25](https://github.com/toy/image_optim/issues/25) [@toy](https://github.com/toy)

## v0.10.0 (2013-12-25)

* Fixed bug with inheritance of `DelegateClass` in jruby 1.9 and 2.0 [@toy](https://github.com/toy)
* Return `ImagePath::Optimized` containing also original path and size from `optimize_image` and `optimize_image!` [#12](https://github.com/toy/image_optim/issues/12) [@toy](https://github.com/toy)
* Show exception backtrace when verbose [@toy](https://github.com/toy)
* Fail if there were warnings with paths to optimize [@toy](https://github.com/toy)
* Rails (sprockets) preprocessor [#2](https://github.com/toy/image_optim/issues/2) [@toy](https://github.com/toy)
* Use fspath ~> 2.1.0 with fixes for jruby 1.7.8 [@toy](https://github.com/toy)
* Add `optimize_image_data` and `optimize_images_data` [@toy](https://github.com/toy)
* Read config from `image_optim.yml` at `XDG_CONFIG_HOME` (`~/.config` by default) and from `.image_optim.yml` in current working directory [#13](https://github.com/toy/image_optim/issues/13) [@toy](https://github.com/toy)
* Added badges to README [@toy](https://github.com/toy)
* Big refactoring [@toy](https://github.com/toy)

## v0.9.1 (2013-08-20)

* Use progress ~> 3.0.0 and in_threads ~> 1.2.0 [@toy](https://github.com/toy)

## v0.9.0 (2013-07-30)

* Use fspath ~> 2.0.5 with bug fix for jruby in 1.8 mode [@toy](https://github.com/toy)
* Overcome wrong implementation of `Process::Status` in jruby [@toy](https://github.com/toy)
* Fix for jruby not `File.rename` not accepting non String [@toy](https://github.com/toy)
* Fix for jruby `File.rename` not accepting non String [@toy](https://github.com/toy)
* Added `.travis.yml` [@toy](https://github.com/toy)
* Added `jhead` worker [@toy](https://github.com/toy)

## v0.8.1 (2013-05-27)

* Fixed variable name in `jpegoptim` worker [@toy](https://github.com/toy)
* Added example of using `PATH` with ImageOptim.app bins [#11](https://github.com/toy/image_optim/issues/11) [@toy](https://github.com/toy)

## v0.8.0 (2013-03-27)

* Print options if verbose [@toy](https://github.com/toy)
* Added worker options to README using script [#5](https://github.com/toy/image_optim/issues/5) [@toy](https://github.com/toy)
* Setting worker options using arguments to image_optim bin [@toy](https://github.com/toy)
* Option definitions with description, default value and validation instead of attribute reader in options [@toy](https://github.com/toy)
* Don't change PATH for ruby process [@toy](https://github.com/toy)
* Vendor `jpegrescan` [@toy](https://github.com/toy)
* Option to use `jpegrescan` in `jpegtran` worker, off by default [#6](https://github.com/toy/image_optim/issues/6) [@toy](https://github.com/toy)

## v0.7.3 (2013-02-24)

* Use image_size ~> 1.1.2 [@toy](https://github.com/toy)

## v0.7.2 (2013-01-18)

* Make `apply_threading` accept enum instead of array [@toy](https://github.com/toy)

## v0.7.1 (2013-01-17)

* Use more compatible redirect syntax `>&` [#9](https://github.com/toy/image_optim/issues/9) [@teaforthecat](https://github.com/teaforthecat)

## v0.7.0 (2013-01-17)

* Use `system` with `env` and `nice` instead of forking [#8](https://github.com/toy/image_optim/issues/8) [@toy](https://github.com/toy)
* Don't use `-s` of `which` as it is nonstandard [#7](https://github.com/toy/image_optim/issues/7) [@toy](https://github.com/toy)
* Added bin resolving with ability to specify binary paths using environment variables [@toy](https://github.com/toy)
* Reorganized workers [@toy](https://github.com/toy)
* Added links to tool projects [@toy](https://github.com/toy)

## v0.6.0 (2012-11-15)

* Warn if directly added files are not images or are not optimizable [@toy](https://github.com/toy)
* Recursively scan directories for images [#4](https://github.com/toy/image_optim/issues/4) [@toy](https://github.com/toy)
* Typo in bin/image_optim  [#3](https://github.com/toy/image_optim/issues/3) [@fabiomcosta](https://github.com/fabiomcosta)

## v0.5.1 (2012-08-07)

* Nice output for configuration and binary resolving errors [@toy](https://github.com/toy)

## v0.5.0 (2012-08-05)

* Verbose output [@toy](https://github.com/toy)

## v0.4.2 (2012-02-26)

* Use image_size ~> 1.1 [@toy](https://github.com/toy)

## v0.4.1 (2012-02-14)

* Added binary installation instructions to README [#1](https://github.com/toy/image_optim/issues/1) [@jingoro](https://github.com/jingoro)

## v0.4.0 (2012-01-13)

* Added usage to README [@toy](https://github.com/toy)
* Allow setting nice level, 10 by default [@toy](https://github.com/toy)
* Use `fork` instead of `system` [@toy](https://github.com/toy)

## v0.3.2 (2012-01-12)

* Fixed setting max thread count [@toy](https://github.com/toy)

## v0.3.1 (2012-01-12)

* Fixed parsing thread option [@toy](https://github.com/toy)

## v0.3.0 (2012-01-12)

* Output size change per file and total [@toy](https://github.com/toy)
* Warn about non files [@toy](https://github.com/toy)

## v0.2.1 (2012-01-11)

* Simplified determining presence of bin [@toy](https://github.com/toy)

## v0.2.0 (2012-01-10)

* Reduce number of created temp files to minimum [@toy](https://github.com/toy)
* Use fspath ~> 2.0.3 [@toy](https://github.com/toy)

## v0.1.0 (2012-01-09)

* Initial release [@toy](https://github.com/toy)
