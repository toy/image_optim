require 'image_optim/option_helpers'
require 'image_optim/configuration_error'
require 'image_optim/hash_helpers'
require 'image_optim/worker'
require 'set'
require 'yaml'

class ImageOptim
  class Config
    include OptionHelpers

    GLOBAL_CONFIG_PATH = File.join(File.expand_path(ENV['XDG_CONFIG_HOME'] || '~/.config'), 'image_optim.yml')
    LOCAL_CONFIG_PATH = '.image_optim.yml'

    class << self
      def global
        File.file?(GLOBAL_CONFIG_PATH) ? read(GLOBAL_CONFIG_PATH) : {}
      end

      def local
        File.file?(LOCAL_CONFIG_PATH) ? read(LOCAL_CONFIG_PATH) : {}
      end

    private

      def read(path)
        config = YAML.load_file(path)
        unless config.is_a?(Hash)
          raise "excpected hash, got #{config.inspect}"
        end
        HashHelpers.deep_symbolise_keys(config)
      rescue => e
        warn "exception when reading #{path}: #{e}"
        {}
      end
    end

    def initialize(options)
      @options = [
        Config.global,
        Config.local,
        HashHelpers.deep_symbolise_keys(options),
      ].inject do |memo, hash|
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
      unknown_options = @options.reject{ |key, value| @used.include?(key) }
      unless unknown_options.empty?
        raise ConfigurationError, "unknown options #{unknown_options.inspect} for #{self}"
      end
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

      threads = case threads
      when true, nil
        processor_count
      when false
        1
      else
        threads.to_i
      end

      OptionHelpers.limit_with_range(threads, 1..16)
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
        raise ConfigurationError, "Got #{worker_options.inspect} for #{klass.name} options"
      end
    end

  private

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
end
