require 'image_optim/bin_resolver'
require 'image_optim/config'
require 'image_optim/handler'
require 'image_optim/image_path'
require 'image_optim/worker'
require 'in_threads'
require 'shellwords'

class ImageOptim
  # Nice level
  attr_reader :nice

  # Number of threads to run with
  attr_reader :threads

  # Verbose output?
  def verbose?
    @verbose
  end

  # Initialize workers, specify options using worker underscored name:
  #
  # pass false to disable worker
  #
  #     ImageOptim.new(:pngcrush => false)
  #
  # or hash with options to worker
  #
  #     ImageOptim.new(:advpng => {:level => 3}, :optipng => {:level => 2})
  #
  # use :threads to set number of parallel optimizers to run (passing true or nil determines number of processors, false disables parallel processing)
  #
  #     ImageOptim.new(:threads => 8)
  #
  # use :nice to specify optimizers nice level (true or nil makes it 10, false makes it 0)
  #
  #     ImageOptim.new(:nice => 20)
  def initialize(options = {})
    @bin_resolver = BinResolver.new

    config = Config.new(options)
    @nice = config.nice
    @threads = config.threads
    @verbose = config.verbose

    @workers_by_format = {}
    Worker.klasses.each do |klass|
      if worker_options = config.for_worker(klass)
        worker = klass.new(self, worker_options)
        worker.image_formats.each do |format|
          @workers_by_format[format] ||= []
          @workers_by_format[format] << worker
        end
      end
    end
    @workers_by_format.each do |format, workers|
      workers.replace workers.sort_by(&:run_order) # There is no sort_by! in ruby 1.8
    end

    config.assert_no_unused_options!

    puts config if verbose?
  end

  # Get workers for image
  def workers_for_image(path)
    @workers_by_format[ImagePath.new(path).format]
  end

  # Optimize one file, return new path or nil if optimization failed
  def optimize_image(original)
    original = ImagePath.new(original)
    if workers = workers_for_image(original)
      handler = Handler.new(original)
      workers.each do |worker|
        handler.process do |src, dst|
          worker.optimize(src, dst)
        end
      end
      handler.result
    end
  end

  # Optimize one file in place, return optimization status
  def optimize_image!(original)
    original = ImagePath.new(original)
    if result = optimize_image(original)
      result.replace(original)
      true
    end
  end

  # Optimize multiple images
  # if block given yields path and result for each image and returns array of yield results
  # else return array of results
  def optimize_images(paths, &block)
    run_method_for(paths, :optimize_image, &block)
  end

  # Optimize multiple images in place
  # if block given yields path and result for each image and returns array of yield results
  # else return array of results
  def optimize_images!(paths, &block)
    run_method_for(paths, :optimize_image!, &block)
  end

  # Optimization methods with default options
  def self.method_missing(method, *args, &block)
    if method.to_s =~ /^optimize_images?\!?$/
      new.send(method, *args, &block)
    else
      super
    end
  end

  # Version of image_optim gem spec loaded
  def self.version
    Gem.loaded_specs['image_optim'].version.to_s rescue 'DEV'
  end

  # Are there workers for file at path?
  def optimizable?(path)
    !!workers_for_image(path)
  end

  # Temp directory for symlinks to bins with path coming from ENV
  def resolve_dir
    @bin_resolver.dir
  end

  # Check existance of binary, create symlink if ENV contains path for key XXX_BIN where XXX is upper case bin name
  def resolve_bin!(bin)
    @bin_resolver.resolve!(bin)
  end

  # Join resolve_dir, default path and vendor path for PATH environment variable
  def env_path
    @bin_resolver.env_path
  end

private

  # Run method for each path and yield each path and result if block given
  def run_method_for(paths, method_name, &block)
    apply_threading(paths).map do |path|
      path = ImagePath.new(path)
      result = send(method_name, path)
      if block
        block.call(path, result)
      else
        result
      end
    end
  end

  # Apply threading if threading is allowed
  def apply_threading(enum)
    if threads > 1
      enum.in_threads(threads)
    else
      enum
    end
  end
end

%w[
  pngcrush pngout optipng advpng
  jhead jpegoptim jpegtran
  gifsicle
].each do |worker|
  require "image_optim/worker/#{worker}"
end
