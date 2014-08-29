# encoding: UTF-8

require 'image_optim/configuration_error'
require 'image_optim/option_definition'
require 'image_optim/option_helpers'
require 'shellwords'
require 'English'

class ImageOptim
  # Base class for all workers
  class Worker
    class << self
      # List of available workers
      def klasses
        @klasses ||= []
      end

      # Remember all classes inheriting from this one
      def inherited(base)
        klasses << base
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

    # Check if operation resulted in optimized file
    def optimized?(src, dst)
      dst.size? && dst.size < src.size
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
      name = self.class.bin_sym
      raise e, "#{name} worker: #{e.message}; please provide proper binary or "\
          "disable this worker (`:#{name} => false`)", e.backtrace
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
      success = system full_command

      status = $CHILD_STATUS
      if status.signaled?
        # jruby does not differ non zero exit status and signal number
        unless defined?(JRUBY_VERSION) && status.exitstatus == status.termsig
          fail SignalException, status.termsig
        end
      end

      success
    end
  end
end
