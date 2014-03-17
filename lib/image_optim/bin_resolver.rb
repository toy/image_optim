require 'thread'
require 'fspath'
require 'image_optim/bin_resolver/simple_version'
require 'image_optim/bin_resolver/comparable_condition'

class ImageOptim
  class BinNotFoundError < StandardError; end
  class BadBinVersion < StandardError; end

  class BinResolver
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
        if bin = resolve?(name) && Bin.new(name, version(name))
          $stderr << "Resolved #{bin}\n" if @image_optim.verbose?
        end
        @bins[name] = bin
      end

      if @bins[name]
        check!(@bins[name])
      else
        raise BinNotFoundError, "`#{name}` not found"
      end
    end

    VENDOR_PATH = File.expand_path('../../../vendor', __FILE__)

    def env_path
      [dir, ENV['PATH'], VENDOR_PATH].compact.join(':')
    end

  private

    def resolving(name)
      unless @bins.include?(name)
        @lock.synchronize do
          unless @bins.include?(name)
            yield
          end
        end
      end
    end

    def resolve?(name)
      if path = ENV["#{name}_bin".upcase]
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
      capture_output("which #{name.to_s.shellescape}") != ''
    end

    def version(name)
      case name.to_sym
      when :advpng, :gifsicle, :jpegoptim, :optipng
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
        date_str = capture_output("#{name} 2>&1")[/[A-Z][a-z]{2} (?: |\d)\d \d{4}/]
        Date.parse(date_str).strftime('%Y%m%d')
      end
    end

    def check!(bin)
      is = ComparableCondition.is
      case bin.name
      when :pngcrush
        case bin.version
        when is.between?('1.7.60', '1.7.65')
          raise BadBinVersion, "`#{bin}` is known to produce broken pngs"
        end
      when :advpng
        case bin.version
        when is < '1.17'
          warn "Note that `#{bin}` does not use zopfli"
        end
      end
    end

    def capture_output(command)
      `env PATH=#{env_path.shellescape} #{command}`
    end
  end
end
