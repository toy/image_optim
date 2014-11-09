require 'image_optim/bin_resolver'
require 'image_optim/config'
require 'image_optim/handler'
require 'image_optim/image_meta'
require 'image_optim/image_path'
require 'image_optim/railtie' if defined?(Rails)
require 'image_optim/worker'
require 'in_threads'
require 'shellwords'

%w[
  pngcrush pngout advpng optipng pngquant
  jhead jpegoptim jpegrecompress jpegtran
  gifsicle
  svgo
].each do |worker|
  require "image_optim/worker/#{worker}"
end

# Main interface
class ImageOptim
  # Nice level
  attr_reader :nice

  # Number of threads to run with
  attr_reader :threads

  # Verbose output?
  attr_reader :verbose

  # Use image_optim_pack
  attr_reader :pack

  # Skip workers with missing or problematic binaries
  attr_reader :skip_missing_workers

  # Allow lossy workers and optimizations
  attr_reader :allow_lossy

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
  # use :threads to set number of parallel optimizers to run (passing true or
  # nil determines number of processors, false disables parallel processing)
  #
  #     ImageOptim.new(:threads => 8)
  #
  # use :nice to specify optimizers nice level (true or nil makes it 10, false
  # makes it 0)
  #
  #     ImageOptim.new(:nice => 20)
  def initialize(options = {})
    config = Config.new(options)
    @verbose = config.verbose
    $stderr << "config:\n#{config.to_s.gsub(/^/, '  ')}" if verbose

    %w[
      nice
      threads
      pack
      skip_missing_workers
      allow_lossy
    ].each do |name|
      instance_variable_set(:"@#{name}", config.send(name))
      $stderr << "#{name}: #{send(name)}\n" if verbose
    end

    @bin_resolver = BinResolver.new(self)

    @workers_by_format = Worker.create_all_by_format(self) do |klass|
      config.for_worker(klass)
    end

    log_workers_by_format if verbose

    config.assert_no_unused_options!
  end

  # Get workers for image
  def workers_for_image(path)
    @workers_by_format[ImagePath.convert(path).format]
  end

  # Optimize one file, return new path as OptimizedImagePath or nil if
  # optimization failed
  def optimize_image(original)
    original = ImagePath.convert(original)
    return unless (workers = workers_for_image(original))
    result = Handler.for(original) do |handler|
      workers.each do |worker|
        handler.process do |src, dst|
          worker.optimize(src, dst)
        end
      end
    end
    return unless result
    ImagePath::Optimized.new(result, original)
  end

  # Optimize one file in place, return original as OptimizedImagePath or nil if
  # optimization failed
  def optimize_image!(original)
    original = ImagePath.convert(original)
    return unless (result = optimize_image(original))
    result.replace(original)
    ImagePath::Optimized.new(original, result.original_size)
  end

  # Optimize image data, return new data or nil if optimization failed
  def optimize_image_data(original_data)
    image_meta = ImageMeta.for_data(original_data)
    return unless image_meta && image_meta.format
    ImagePath.temp_file %W[image_optim .#{image_meta.format}] do |temp|
      temp.binmode
      temp.write(original_data)
      temp.close

      if (result = optimize_image(temp.path))
        result.binread
      end
    end
  end

  # Optimize multiple images
  # if block given yields path and result for each image and returns array of
  # yield results
  # else return array of path and result pairs
  def optimize_images(paths, &block)
    run_method_for(paths, :optimize_image, &block)
  end

  # Optimize multiple images in place
  # if block given yields path and result for each image and returns array of
  # yield results
  # else return array of path and result pairs
  def optimize_images!(paths, &block)
    run_method_for(paths, :optimize_image!, &block)
  end

  # Optimize multiple image datas
  # if block given yields original and result for each image data and returns
  # array of yield results
  # else return array of path and result pairs
  def optimize_images_data(datas, &block)
    run_method_for(datas, :optimize_image_data, &block)
  end

  # Optimization methods with default options
  def self.method_missing(method, *args, &block)
    if method_defined?(method) && method.to_s =~ /^optimize_image/
      new.send(method, *args, &block)
    else
      super
    end
  end

  # Version of image_optim gem spec loaded
  def self.version
    Gem.loaded_specs['image_optim'].version.to_s rescue 'DEV'
  end

  # Full version of image_optim
  def self.full_version
    "image_optim v#{version}"
  end

  # Are there workers for file at path?
  def optimizable?(path)
    !!workers_for_image(path)
  end

  # Check existance of binary, create symlink if ENV contains path for key
  # XXX_BIN where XXX is upper case bin name
  def resolve_bin!(bin)
    @bin_resolver.resolve!(bin)
  end

  # Join resolve_dir, default path and vendor path for PATH environment variable
  def env_path
    @bin_resolver.env_path
  end

private

  def log_workers_by_format
    $stderr << "Workers by format:\n"
    @workers_by_format.each do |format, workers|
      $stderr << "#{format}:\n"
      workers.each do |worker|
        $stderr << "  #{worker.class.bin_sym}:\n"
        worker.options.each do |name, value|
          $stderr << "    #{name}: #{value.inspect}\n"
        end
      end
    end
  end

  # Run method for each item in list
  # if block given yields item and result for item and returns array of yield
  # results
  # else return array of item and result pairs
  def run_method_for(list, method_name, &block)
    apply_threading(list).map do |item|
      result = send(method_name, item)
      if block
        block.call(item, result)
      else
        [item, result]
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
