require 'image_optim/option_helpers'
require 'image_optim/configuration_error'
require 'image_optim/hash_helpers'
require 'image_optim/worker'
require 'image_optim/cmd'
require 'set'
require 'yaml'

class ImageOptim
  # Read, merge and parse configuration
  class Config
    include OptionHelpers

    # Global config path at `$XDG_CONFIG_HOME/image_optim.yml` (by default
    # `~/.config/image_optim.yml`)
    GLOBAL_PATH = begin
      File.join(ENV['XDG_CONFIG_HOME'] || '~/.config', 'image_optim.yml')
    end

    # Local config path at `./.image_optim.yml`
    LOCAL_PATH = './.image_optim.yml'.freeze

    class << self
      # Read options at path: expand path (warn on failure), return {} if file
      # does not exist or is empty, read yaml, check if it is a Hash, deep
      # symbolise keys
      def read_options(path)
        begin
          full_path = File.expand_path(path)
        rescue ArgumentError => e
          warn "Can't expand path #{path}: #{e}"
          return {}
        end
        return {} unless File.size?(full_path)
        config = YAML.load_file(full_path)
        unless config.is_a?(Hash)
          fail "expected hash, got #{config.inspect}"
        end
        HashHelpers.deep_symbolise_keys(config)
      rescue => e
        warn "exception when reading #{full_path}: #{e}"
        {}
      end
    end

    # Merge config from files with passed options
    # Config files are checked at `GLOBAL_PATH` and `LOCAL_PATH` unless
    # overriden using `:config_paths`
    def initialize(options)
      config_paths = options.delete(:config_paths) || [GLOBAL_PATH, LOCAL_PATH]
      config_paths = Array(config_paths)

      to_merge = config_paths.map{ |path| self.class.read_options(path) }
      to_merge << HashHelpers.deep_symbolise_keys(options)

      @options = to_merge.reduce do |memo, hash|
        HashHelpers.deep_merge(memo, hash)
      end
      @used = Set.new
    end

    # Gets value for key converted to symbol and mark option as used
    def get!(key)
      key = key.to_sym
      @used << key
      @options[key]
    end

    # Check if key is present
    def key?(key)
      key = key.to_sym
      @options.key?(key)
    end

    # Fail unless all options were marked as used (directly or indirectly
    # accessed using `get!`)
    def assert_no_unused_options!
      unknown_options = @options.reject{ |key, _value| @used.include?(key) }
      return if unknown_options.empty?
      fail ConfigurationError, "unknown options #{unknown_options.inspect}"
    end

    # Nice level:
    # * `10` by default and for `nil` or `true`
    # * `0` for `false`
    # * otherwise convert to integer
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

    # Number of parallel threads:
    # * `processor_count` by default and for `nil` or `true`
    # * `1` for `false`
    # * otherwise convert to integer
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

    # Verbose mode, converted to boolean
    def verbose
      !!get!(:verbose)
    end

    # Using image_optim_pack:
    # * `false` to disable
    # * `nil` to use if available
    # * everything else to require
    def pack
      pack = get!(:pack)
      return false if pack == false

      require 'image_optim/pack'
      true
    rescue LoadError => e
      raise "Cannot load image_optim_pack: #{e}" if pack
      false
    end

    # Skip missing workers, converted to boolean
    def skip_missing_workers
      if key?(:skip_missing_workers)
        !!get!(:skip_missing_workers)
      else
        pack
      end
    end

    # Allow lossy workers and optimizations, converted to boolean
    def allow_lossy
      !!get!(:allow_lossy)
    end

    def cache_dir
      dir = get!(:cache_dir)
      dir unless dir.nil? || dir.empty?
    end

    def cache_worker_digests
      !!get!(:cache_worker_digests)
    end

    # Options for worker class by its `bin_sym`:
    # * `Hash` passed as is
    # * `{}` for `true` or `nil`
    # * `false` for `false`
    # * otherwise fail with `ConfigurationError`
    def for_worker(klass)
      worker_options = get!(klass.bin_sym)

      case worker_options
      when Hash
        worker_options
      when true, nil
        {}
      when false
        {:disable => true}
      else
        fail ConfigurationError, "Got #{worker_options.inspect} for "\
            "#{klass.name} options"
      end
    end

    # yaml dump without document beginning prefix `---`
    def to_s
      YAML.dump(HashHelpers.deep_stringify_keys(@options)).sub(/\A---\n/, '')
    end

  private

    # http://stackoverflow.com/a/6420817
    def processor_count
      @processor_count ||= case host_os = RbConfig::CONFIG['host_os']
      when /darwin9/
        Cmd.capture 'hwprefs cpu_count'
      when /darwin/
        if (Cmd.capture 'which hwprefs') != ''
          Cmd.capture 'hwprefs thread_count'
        else
          Cmd.capture 'sysctl -n hw.ncpu'
        end
      when /linux/
        Cmd.capture 'grep -c processor /proc/cpuinfo'
      when /freebsd/
        Cmd.capture 'sysctl -n hw.ncpu'
      when /mswin|mingw/
        require 'win32ole'
        query = 'select NumberOfLogicalProcessors from Win32_Processor'
        result = WIN32OLE.connect('winmgmts://').ExecQuery(query)
        result.to_enum.first.NumberOfLogicalProcessors
      else
        warn "Unknown architecture (#{host_os}) assuming one processor."
        1
      end.to_i
    end
  end
end
