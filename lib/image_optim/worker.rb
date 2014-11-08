# encoding: UTF-8

require 'image_optim/bin_resolver'
require 'image_optim/configuration_error'
require 'image_optim/option_definition'
require 'image_optim/option_helpers'
require 'image_optim/cmd'
require 'shellwords'
require 'English'

class ImageOptim
  # Base class for all workers
  class Worker
    @klasses = []

    class << self
      # Default init for worker is new
      # Check example of override in gifsicle worker
      alias_method :init, :new

      # List of available workers
      def klasses
        @klasses.to_enum
      end

      # Remember all classes inheriting from this one
      def inherited(base)
        @klasses << base
      end

      # Underscored class name symbol
      def bin_sym
        @underscored_name ||= name.
          split('::').last. # get last part
          gsub(/([a-z])([A-Z])/, '\1_\2').downcase. # convert AbcDef to abc_def
          to_sym
      end

      def option_definitions
        @option_definitions ||= []
      end

      def option(name, default, type, description = nil, &proc)
        attr_reader name
        option_definitions <<
          OptionDefinition.new(name, default, type, description, &proc)
      end

      # Create hash with format mapped to list of workers sorted by run order
      def create_all_by_format(image_optim, &options_proc)
        by_format = {}
        create_all(image_optim, &options_proc).each do |worker|
          worker.image_formats.each do |format|
            by_format[format] ||= []
            by_format[format] << worker
          end
        end
        by_format
      end

      # Create list of workers sorted by run order
      # Workers are initialized with options provided through options_proc
      # Resolve all bins of all workers, if there are errors and
      # skip_missing_workers of image_optim is true - show warnings, otherwise
      # fail with one joint exception
      def create_all(image_optim, &options_proc)
        workers = init_all(image_optim, &options_proc)

        resolved = []
        errors = BinResolver.collect_errors(workers) do |worker|
          worker.resolve_used_bins!
          resolved << worker
        end

        unless errors.empty?
          if image_optim.skip_missing_workers
            errors.each{ |error| warn error }
          else
            message = ['Bin resolving errors:', *errors].join("\n")
            fail BinResolver::Error, message
          end
        end

        resolved.sort_by.with_index{ |worker, i| [worker.run_order, i] }
      end

    private

      def init_all(image_optim, &options_proc)
        klasses.map do |klass|
          next unless (options = options_proc[klass])
          klass.init(image_optim, options)
        end.compact.flatten
      end
    end

    # Configure (raises on extra options)
    def initialize(image_optim, options = {})
      unless image_optim.is_a?(ImageOptim)
        fail ArgumentError, 'first parameter should be an ImageOptim instance'
      end
      @image_optim = image_optim
      self.class.option_definitions.each do |option_definition|
        value = if options.key?(option_definition.name)
          options[option_definition.name]
        else
          option_definition.default
        end
        if option_definition.proc
          value = option_definition.proc[value]
        end
        instance_variable_set("@#{option_definition.name}", value)
      end

      assert_no_unknown_options!(options)
    end

    # Return hash with worker options
    def options
      hash = {}
      self.class.option_definitions.each do |option|
        hash[option.name] = send(option.name)
      end
      hash
    end

    # Optimize image at src, output at dst, must be overriden in subclass
    # return true on success
    def optimize(_src, _dst)
      fail NotImplementedError, "implement method optimize in #{self.class}"
    end

    # List of formats which worker can optimize
    def image_formats
      format_from_name = self.class.name.downcase[/gif|jpeg|png|svg/]
      unless format_from_name
        fail "#{self.class}: can't guess applicable format from worker name"
      end
      [format_from_name.to_sym]
    end

    # Ordering in list of workers, 0 by default
    def run_order
      0
    end

    # List of bins used by worker
    def used_bins
      [self.class.bin_sym]
    end

    # Resolve used bins, raise exception concatenating all messages
    def resolve_used_bins!
      errors = BinResolver.collect_errors(used_bins) do |bin|
        @image_optim.resolve_bin!(bin)
      end
      return if errors.empty?
      fail BinResolver::Error, wrap_resolver_error_message(errors.join(', '))
    end

    # Check if operation resulted in optimized file
    def optimized?(src, dst)
      dst.size? && dst.size < src.size
    end

    # Short inspect
    def inspect
      options_string = options.map do |name, value|
        " @#{name}=#{value.inspect}"
      end.join(',')
      "#<#{self.class}#{options_string}>"
    end

  private

    def assert_no_unknown_options!(options)
      known_keys = self.class.option_definitions.map(&:name)
      unknown_options = options.reject{ |key, _value| known_keys.include?(key) }
      return if unknown_options.empty?
      fail ConfigurationError, "unknown options #{unknown_options.inspect} "\
          "for #{self}"
    end

    # Forward bin resolving to image_optim
    def resolve_bin!(bin)
      @image_optim.resolve_bin!(bin)
    rescue BinResolver::Error => e
      raise e, wrap_resolver_error_message(e.message), e.backtrace
    end

    def wrap_resolver_error_message(message)
      name = self.class.bin_sym
      "#{name} worker: #{message}; please provide proper binary or "\
          "disable this worker (--no-#{name} argument or "\
          "`:#{name} => false` through options)"
    end

    # Run command setting priority and hiding output
    def execute(bin, *arguments)
      command = build_command!(bin, *arguments)

      start = Time.now

      success = run_command(command)

      if @image_optim.verbose
        $stderr << "#{success ? '✓' : '✗'} #{Time.now - start}s #{command}\n"
      end

      success
    end

    # Build command string
    def build_command!(bin, *arguments)
      resolve_bin!(bin)

      [bin, *arguments].map(&:to_s).shelljoin
    end

    # Run command defining environment, setting nice level, removing output and
    # reraising signal exception
    def run_command(command)
      full_command = %W[
        env PATH=#{@image_optim.env_path.shellescape}
        nice -n #{@image_optim.nice}
        #{command} > /dev/null 2>&1
      ].join(' ')
      Cmd.run full_command
    end
  end
end
