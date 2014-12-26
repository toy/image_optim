# ChangeLog

## unreleased

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

* Use more compatible redirect syntax `>&` [#9](https://github.com/toy/image_optim/issues/9) @"Chris Thompson"

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
