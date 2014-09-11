require 'image_optim/option_helpers'
require 'image_optim/configuration_error'
require 'image_optim/hash_helpers'
require 'image_optim/worker'
require 'set'
require 'yaml'

class ImageOptim
  # Read, merge and parse configuration
  class Config
    include OptionHelpers

    CONFIG_HOME = ENV['XDG_CONFIG_HOME'] || '~/.config'
    GLOBAL_CONFIG_PATH = File.join(CONFIG_HOME, 'image_optim.yml')
    LOCAL_CONFIG_PATH = './.image_optim.yml'

    class << self
      # Read config at GLOBAL_CONFIG_PATH if it exists, warn if anything is
      # wrong
      def global
        read(GLOBAL_CONFIG_PATH)
      end

      # Read config at LOCAL_CONFIG_PATH if it exists, warn if anything is
      # wrong
      def local
        read(LOCAL_CONFIG_PATH)
      end

    private

      def read(path)
        begin
          full_path = File.expand_path(path)
        rescue ArgumentError => e
          warn "Can't expand path #{path}: #{e}"
          return {}
        end
        return {} unless File.file?(full_path)
        config = YAML.load_file(full_path)
        unless config.is_a?(Hash)
          fail "excpected hash, got #{config.inspect}"
        end
        HashHelpers.deep_symbolise_keys(config)
      rescue => e
        warn "exception when reading #{full_path}: #{e}"
        {}
      end
    end

    def initialize(options)
      @options = [
        Config.global,
        Config.local,
        HashHelpers.deep_symbolise_keys(options),
      ].reduce do |memo, hash|
        HashHelpers.deep_merge(memo, hash)
      end
      @used = Set.new
    end

    def get!(key)
      key = key.to_sym
      @used << key
      @options[key]
    end

    def assert_no_unused_options!
      unknown_options = @options.reject{ |key, _value| @used.include?(key) }
      return if unknown_options.empty?
      fail ConfigurationError, "unknown options #{unknown_options.inspect}"
    end

    def nice
      nice = get!(:nice)

      case nice
      when true, nil
        10
      when false
        0
      else
        nice.to_i
      end
    end

    def threads
      threads = get!(:threads)

      case threads
      when true, nil
        processor_count
      when false
        1
      else
        threads.to_i
      end
    end

    def verbose
      !!get!(:verbose)
    end

    def for_worker(klass)
      worker_options = get!(klass.bin_sym)

      case worker_options
      when Hash
        worker_options
      when true, nil
        {}
      when false
        false
      else
        fail ConfigurationError, "Got #{worker_options.inspect} for "\
            "#{klass.name} options"
      end
    end

    def to_s
      YAML.dump(HashHelpers.deep_stringify_keys(@options)).sub(/\A---\n/, '')
    end

  private

    # http://stackoverflow.com/a/6420817
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
        WIN32OLE.
          connect('winmgmts://').
          ExecQuery('select NumberOfLogicalProcessors from Win32_Processor').
          to_enum.first.NumberOfLogicalProcessors
      else
        warn "Unknown architecture (#{host_os}) assuming one processor."
        1
      end.to_i
    end
  end
end
