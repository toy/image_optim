require 'thread'
require 'fspath'
require 'image_optim/bin_resolver/error'
require 'image_optim/bin_resolver/bin'

class ImageOptim
  # Handles resolving binaries and checking versions
  #
  # If there is an environment variable XXX_BIN when resolving xxx, then a
  # symlink to binary will be created in a temporary directory which will be
  # added to PATH
  class BinResolver
    class BinNotFound < Error; end

    # Directory for symlinks to bins if XXX_BIN was used
    attr_reader :dir

    def initialize(image_optim)
      @image_optim = image_optim
      @bins = {}
      @lock = Mutex.new
    end

    # Binary resolving: create symlink if there is XXX_BIN environment variable,
    # build Bin with full path using `command -v`, check binary version
    # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/command.html
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

    # Check path in XXX_BIN to exist, be a file and be executable and symlink to
    # dir as name
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
