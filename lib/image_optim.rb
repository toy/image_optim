require 'in_threads'

class ImageOptim
  autoload :ImagePath, 'image_optim/image_path'
  autoload :OptionHelpers, 'image_optim/option_helpers'
  autoload :Util, 'image_optim/util'
  autoload :Worker, 'image_optim/worker'

  include OptionHelpers

  # Hash of initialized workers by format they apply to
  attr_reader :workers_by_format

  # Number of threads to run with
  attr_reader :threads

  # Initialize workers, specify options using worker underscored name:
  #
  # pass false to disable worker
  #
  #     ImageOptim.new(:pngcrush => false)
  #
  # string to set binary
  #
  #     ImageOptim.new(:pngout => '/special/path/bin/pngout123')
  #
  # or hash with options to worker and :bin specifying binary
  #
  #     ImageOptim.new(:advpng => {:level => 3}, :optipng => {:level => 2}, :jpegoptim => {:bin => 'jpegoptim345'})
  def initialize(options = {})
    @workers_by_format = {}
    Worker.klasses.each do |klass|
      case worker_options = options.delete(klass.underscored_name.to_sym)
      when Hash
      when true, nil
        worker_options = {}
      when false
        next
      when String
        worker_options = {:bin => worker_options}
      else
        raise "Got #{worker_options.inspect} for #{klass.name} options"
      end
      worker = klass.new(worker_options)
      klass.image_formats.each do |format|
        @workers_by_format[format] ||= []
        @workers_by_format[format] << worker
      end
    end
    @workers_by_format.each do |format, workers|
      workers.replace workers.sort_by(&:run_priority)
    end

    threads = case options[:threads]
    when true, nil
      Util.processor_count
    when false
      1
    else
      options[:threads].to_i
    end
    @threads = limit_with_range(threads, 1..16)

    assert_options_empty!(options)
  end

  # Get workers for image
  def workers_for_image(path)
    @workers_by_format[ImagePath.new(path).format]
  end

  # Optimize one file, return new path or nil if optimization failed
  def optimize_image(original)
    original = ImagePath.new(original)
    if workers = workers_for_image(original)
      result = nil
      ts = [original, original.temp_path]
      workers.each do |worker|
        if result && ts.length < 3
          ts << original.temp_path
        end
        if worker.optimize(*ts.last(2))
          result = ts.last
          if ts.length == 3
            ts[-2, 2] = ts[-1], ts[-2]
          end
        end
      end
      result
    end
  end

  # Optimize one file in place, return optimization status
  def optimize_image!(original)
    original = ImagePath.new(original)
    if result = optimize_image(original)
      original.temp_path(original.dirname) do |temp|
        original.copy(temp)
        temp.write(result.read)
        temp.rename(original)
      end
      true
    end
  end

  # Optimize multiple images, returning list of results
  # yields path and result if block given
  def optimize_images(paths)
    apply_threading(paths).map do |path|
      result = optimize_image(path)
      yield path, result if block_given?
      result
    end
  end

  # Optimize multiple images in place, returning list of results
  # yields path and result if block given
  def optimize_images!(paths)
    apply_threading(paths).map do |path|
      result = optimize_image!(path)
      yield path, result if block_given?
      result
    end
  end

  # Optimization methods with default options
  def self.method_missing(method, *args, &block)
    if method.to_s =~ /^optimize/
      new.send(method, *args, &block)
    else
      super
    end
  end

  def self.version
    Gem.loaded_specs['image_optim'].version.to_s rescue nil
  end

private

  def apply_threading(array)
    if threads > 1 && array.length > 1
      array.in_threads(threads)
    else
      array
    end
  end
end

%w[
  pngcrush pngout optipng advpng
  jpegoptim jpegtran
  gifsicle
].each do |worker|
  require "image_optim/workers/#{worker}"
end
