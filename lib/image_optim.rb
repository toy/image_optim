require 'in_threads'
require 'shellwords'

require 'image_optim/image_path'
require 'image_optim/option_helpers'
require 'image_optim/option_definition'
require 'image_optim/worker'

class ImageOptim
  class ConfigurationError < StandardError; end
  class BinNotFoundError < StandardError; end

  class TrueFalseNil; end

  include OptionHelpers

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
    @resolved_bins = {}
    @resolver_lock = Mutex.new

    nice = options.delete(:nice)
    @nice = case nice
    when true, nil
      10
    when false
      0
    else
      nice.to_i
    end

    threads = options.delete(:threads)
    threads = case threads
    when true, nil
      processor_count
    when false
      1
    else
      threads.to_i
    end
    @threads = OptionHelpers.limit_with_range(threads, 1..16)

    @verbose = !!options.delete(:verbose)

    @workers_by_format = {}
    Worker.klasses.each do |klass|
      case worker_options = options.delete(klass.bin_sym)
      when Hash
      when true, nil
        worker_options = {}
      when false
        next
      else
        raise ConfigurationError, "Got #{worker_options.inspect} for #{klass.name} options"
      end
      worker = klass.new(self, worker_options)
      worker.image_formats.each do |format|
        @workers_by_format[format] ||= []
        @workers_by_format[format] << worker
      end
    end
    @workers_by_format.each do |format, workers|
      workers.replace workers.sort_by(&:run_order) # There is no sort_by! in ruby 1.8
    end

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
  attr_reader :resolve_dir

  # Check existance of binary, create symlink if ENV contains path for key XXX_BIN where XXX is upper case bin name
  def resolve_bin!(bin)
    bin = bin.to_sym
    @resolved_bins.include?(bin) || @resolver_lock.synchronize do
      @resolved_bins.include?(bin) || begin
        if path = ENV["#{bin}_bin".upcase]
          unless @resolve_dir
            @resolve_dir = FSPath.temp_dir
            at_exit{ FileUtils.remove_entry_secure @resolve_dir }
          end
          symlink = @resolve_dir / bin
          symlink.make_symlink(File.expand_path(path))
          at_exit{ symlink.unlink }

          @resolved_bins[bin] = bin_accessible?(symlink)
        else
          @resolved_bins[bin] = bin_accessible?(bin)
        end
      end
    end
    @resolved_bins[bin] or raise BinNotFoundError, "`#{bin}` not found"
  end

  VENDOR_PATH = File.expand_path('../../vendor', __FILE__)

  # Join resolve_dir, default path and vendor path for PATH environment variable
  def env_path
    "#{resolve_dir}:#{ENV['PATH']}:#{VENDOR_PATH}"
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

  # Check if bin can be accessed
  def bin_accessible?(bin)
    `env PATH=#{env_path.shellescape} which #{bin.to_s.shellescape}` != ''
  end

  # http://stackoverflow.com/questions/891537/ruby-detect-number-of-cpus-installed
  def processor_count
    @processor_count ||= case host_os = RbConfig::CONFIG['host_os']
    when /darwin9/
      `hwprefs cpu_count`
    when /darwin/
      (`which hwprefs` != '') ? `hwprefs thread_count` : `sysctl -n hw.ncpu`
    when /linux/
      `grep -c processor /proc/cpuinfo`
    when /freebsd/
      `sysctl -n hw.ncpu`
    when /mswin|mingw/
      require 'win32ole'
      wmi = WIN32OLE.connect('winmgmts://')
      cpu = wmi.ExecQuery('select NumberOfLogicalProcessors from Win32_Processor')
      cpu.to_enum.first.NumberOfLogicalProcessors
    else
      warn "Unknown architecture (#{host_os}) assuming one processor."
      1
    end.to_i
  end
end

%w[
  pngcrush pngout optipng advpng
  jhead jpegoptim jpegtran
  gifsicle
].each do |worker|
  require "image_optim/worker/#{worker}"
end
