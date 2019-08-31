# frozen_string_literal: true

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

    # Path to pack from image_optim_pack if used
    attr_reader :pack_path

    def initialize(image_optim)
      @image_optim = image_optim
      @bins = {}
      @lock = Mutex.new
      init_pack
    end

    # Binary resolving: create symlink if there is XXX_BIN environment variable,
    # build Bin with full path, check binary version
    # Return Bin instance
    def resolve!(name)
      name = name.to_sym

      resolving(name) do
        path = symlink_custom_bin!(name) || full_path(name)
        bin = Bin.new(name, path) if path

        if bin && @image_optim.verbose
          $stderr << "Resolved #{bin}\n"
        end

        @bins[name] = bin

        bin.check! if bin
      end

      fail BinNotFound, "`#{name}` not found" unless @bins[name]

      @bins[name].check_fail!

      @bins[name]
    end

    # Path to vendor at root of image_optim
    VENDOR_PATH = File.expand_path('../../../vendor', __FILE__)

    # Prepand `dir` and append `VENDOR_PATH` to `PATH` from environment
    def env_path
      [
        dir,
        pack_path,
        ENV['PATH'],
        VENDOR_PATH,
      ].compact.join(File::PATH_SEPARATOR)
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

    def init_pack
      return unless @image_optim.pack

      @pack_path = if @image_optim.verbose
        Pack.path do |message|
          $stderr << "#{message}\n"
        end
      else
        Pack.path
      end
      return if @pack_path

      warn 'No pack for this OS and/or ARCH, check verbose output'
    end

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

      if @image_optim.verbose
        $stderr << "Custom path for #{name} specified in #{env_name}: #{path}\n"
      end
      unless @dir
        @dir = FSPath.temp_dir
        at_exit{ FileUtils.remove_entry_secure @dir }
      end
      symlink = @dir / name
      symlink.make_symlink(path)
      path
    end

    # Return full path to bin or null
    # based on http://stackoverflow.com/a/5471032/96823
    def full_path(name)
      # PATHEXT is needed only for windows
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      env_path.split(File::PATH_SEPARATOR).each do |dir|
        exts.each do |ext|
          path = File.expand_path("#{name}#{ext}", dir)
          return path if File.file?(path) && File.executable?(path)
        end
      end
      nil
    end
  end
end
