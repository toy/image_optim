require 'thread'
require 'fspath'
require 'image_optim/bin_resolver/simple_version'
require 'image_optim/bin_resolver/comparable_condition'

class ImageOptim
  # Handles resolving binaries and checking versions
  #
  # If there is an environment variable XXX_BIN when resolbing xxx, then a
  # symlink to binary will be created in a temporary directory which will be
  # added to PATH
  class BinResolver
    class Error < StandardError; end
    class BinNotFound < Error; end
    class BadBinVersion < Error; end

    # Holds name and version of an executable
    class Bin
      attr_reader :name, :version
      def initialize(name, version)
        @name = name
        @version = version && SimpleVersion.new(version)
      end

      def to_s
        "#{@name} #{@version || '-'}"
      end
    end

    attr_reader :dir
    def initialize(image_optim)
      @image_optim = image_optim
      @bins = {}
      @lock = Mutex.new
    end

    def resolve!(name)
      name = name.to_sym

      resolving(name) do
        bin = Bin.new(name, version(name)) if resolve?(name)
        if bin && @image_optim.verbose
          $stderr << "Resolved #{bin}\n"
        end
        @bins[name] = bin
      end

      if @bins[name]
        check!(@bins[name])
      else
        fail BinNotFound, "`#{name}` not found"
      end
    end

    VENDOR_PATH = File.expand_path('../../../vendor', __FILE__)

    def env_path
      [dir, ENV['PATH'], VENDOR_PATH].compact.join(':')
    end

  private

    def resolving(name)
      return if @bins.include?(name)
      @lock.synchronize do
        yield unless @bins.include?(name)
      end
    end

    def resolve?(name)
      if (path = ENV["#{name}_bin".upcase])
        unless @dir
          @dir = FSPath.temp_dir
          at_exit{ FileUtils.remove_entry_secure @dir }
        end
        symlink = @dir / name
        symlink.make_symlink(File.expand_path(path))
      end
      accessible?(name)
    end

    def accessible?(name)
      !!version(name)
    end

    def version(name)
      case name.to_sym
      when :advpng, :gifsicle, :jpegoptim, :optipng, :pngquant
        capture_output("#{name} --version")[/\d+(\.\d+){1,}/]
      when :svgo
        capture_output("#{name} --version 2>&1")[/\d+(\.\d+){1,}/]
      when :jhead
        capture_output("#{name} -V")[/\d+(\.\d+){1,}/]
      when :jpegtran
        capture_output("#{name} -v - 2>&1")[/version (\d+\S*)/, 1]
      when :pngcrush
        capture_output("#{name} -version 2>&1")[/\d+(\.\d+){1,}/]
      when :pngout
        date_regexp = /[A-Z][a-z]{2} (?: |\d)\d \d{4}/
        date_str = capture_output("#{name} 2>&1")[date_regexp]
        Date.parse(date_str).strftime('%Y%m%d')
      end
    end

    def check!(bin)
      is = ComparableCondition.is
      case bin.name
      when :pngcrush
        case bin.version
        when c = is.between?('1.7.60', '1.7.65')
          fail BadBinVersion, "`#{bin}` (#{c}) is known to produce broken pngs"
        end
      when :advpng
        case bin.version
        when c = is < '1.17'
          warn "Note that `#{bin}` (#{c}) does not use zopfli"
        end
      when :pngquant
        case bin.version
        when c = is < '2.0'
          fail BadBinVersion, "`#{bin}` (#{c}) is not supported"
        when c = is < '2.1'
          warn "Note that `#{bin}` (#{c}) may be lossy even with quality `100-`"
        end
      end
    end

    def capture_output(command)
      `env PATH=#{env_path.shellescape} #{command}`
    end
  end
end
