require 'thread'
require 'fspath'
require 'image_optim/bin_resolver/error'
require 'image_optim/bin_resolver/simple_version'
require 'image_optim/bin_resolver/comparable_condition'

class ImageOptim
  # Handles resolving binaries and checking versions
  #
  # If there is an environment variable XXX_BIN when resolving xxx, then a
  # symlink to binary will be created in a temporary directory which will be
  # added to PATH
  class BinResolver
    class BinNotFound < Error; end

    # Holds name and version of an executable
    class Bin
      class BadVersion < Error; end

      attr_reader :name, :path, :version
      def initialize(name, path)
        @name = name.to_sym
        @path = path
        @version = detect_version
      end

      def to_s
        "#{@name} #{@version || '?'} at #{@path}"
      end

      def check!
        fail BadVersion, "didn't get version of `#{self}`" unless version

        is = ComparableCondition.is
        case name
        when :pngcrush
          case version
          when c = is.between?('1.7.60', '1.7.65')
            fail BadVersion, "`#{self}` (#{c}) is known to produce broken pngs"
          end
        when :advpng
          case version
          when c = is < '1.17'
            warn "Note that `#{self}` (#{c}) does not use zopfli"
          end
        when :pngquant
          case version
          when c = is < '2.0'
            fail BadVersion, "`#{self}` (#{c}) is not supported"
          when c = is < '2.1'
            warn "Note that `#{self}` (#{c}) may be lossy even with quality `100-`"
          end
        end
      end

    private

      def detect_version
        str = version_string
        str && SimpleVersion.new(str)
      end

      def version_string
        case name
        when :advpng, :gifsicle, :jpegoptim, :optipng, :pngquant
          `#{path.shellescape} --version 2> /dev/null`[/\d+(\.\d+){1,}/]
        when :svgo
          `#{path.shellescape} --version 2>&1`[/\d+(\.\d+){1,}/]
        when :jhead
          `#{path.shellescape} -V 2> /dev/null`[/\d+(\.\d+){1,}/]
        when :jpegtran
          `#{path.shellescape} -v - 2>&1`[/version (\d+\S*)/, 1]
        when :pngcrush
          `#{path.shellescape} -version 2>&1`[/\d+(\.\d+){1,}/]
        when :pngout
          date_regexp = /[A-Z][a-z]{2} (?: |\d)\d \d{4}/
          date_str = `#{path.shellescape} 2>&1`[date_regexp]
          Date.parse(date_str).strftime('%Y%m%d') if date_str
        when :jpegrescan
          # jpegrescan has no version so just check presence
          path && '-'
        else
          fail "getting `#{name}` version is not defined"
        end
      end
    end

    # Directory for symlinks to bins if XXX_BIN was used
    attr_reader :dir

    def initialize(image_optim)
      @image_optim = image_optim
      @bins = {}
      @lock = Mutex.new
    end

    def resolve!(name)
      name = name.to_sym

      resolving(name) do
        symlink_custom_bin!(name)

        path = full_path(name)
        bin = Bin.new(name, path) if path

        if bin && @image_optim.verbose
          $stderr << "Resolved #{bin}\n"
        end

        @bins[name] = bin
      end

      if @bins[name]
        @bins[name].check!
      else
        fail BinNotFound, "`#{name}` not found"
      end
    end

    # Path to vendor at root of image_optim
    VENDOR_PATH = File.expand_path('../../../vendor', __FILE__)

    # Prepand `dir` and append `VENDOR_PATH` to `PATH` from environment
    def env_path
      [dir, ENV['PATH'], VENDOR_PATH].compact.join(':')
    end

    # Collect resolving errors when running block over items of enumerable
    def self.collect_errors(enumerable)
      errors = []
      enumerable.each do |item|
        begin
          yield item
        rescue Error => e
          errors << e
        end
      end
      errors
    end

  private

    # Double-checked locking
    def resolving(name)
      return if @bins.include?(name)
      @lock.synchronize do
        yield unless @bins.include?(name)
      end
    end

    def symlink_custom_bin!(name)
      env_name = "#{name}_bin".upcase
      path = ENV[env_name]
      return unless path
      path = File.expand_path(path)
      desc = "`#{path}` specified in #{env_name}"
      fail "#{desc} doesn\'t exist" unless File.exist?(path)
      fail "#{desc} is not a file" unless File.file?(path)
      fail "#{desc} is not executable" unless File.executable?(path)
      unless @dir
        @dir = FSPath.temp_dir
        at_exit{ FileUtils.remove_entry_secure @dir }
      end
      symlink = @dir / name
      symlink.make_symlink(path)
    end

    # Return full path to bin or null
    def full_path(name)
      path = capture_output("command -v #{name} 2> /dev/null").strip
      path unless path.empty?
    end

    # Get output of command with path set to `env_path`
    def capture_output(command)
      `env PATH=#{env_path.shellescape} #{command}`
    end
  end
end
