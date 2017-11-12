# encoding: UTF-8

require 'image_optim/cmd'
require 'image_optim/configuration_error'
require 'image_optim/path'
require 'image_optim/worker/class_methods'
require 'shellwords'
require 'English'

class ImageOptim
  # Base class for all workers
  class Worker
    extend ClassMethods

    class << self
      # Default init for worker is new
      # Check example of override in gifsicle worker
      alias_method :init, :new
    end

    # Configure (raises on extra options)
    def initialize(image_optim, options = {})
      unless image_optim.is_a?(ImageOptim)
        fail ArgumentError, 'first parameter should be an ImageOptim instance'
      end
      @image_optim = image_optim
      parse_options(options)
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
      dst_size = dst.size?
      dst_size && dst_size < src.size
    end

    # Short inspect
    def inspect
      options_string = self.class.option_definitions.map do |option|
        " @#{option.name}=#{send(option.name).inspect}"
      end.join(',')
      "#<#{self.class}#{options_string}>"
    end

  private

    def parse_options(options)
      self.class.option_definitions.each do |option_definition|
        value = option_definition.value(self, options)
        instance_variable_set("@#{option_definition.name}", value)
      end
    end

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
      resolve_bin!(bin)

      cmd_args = [bin, *arguments].map(&:to_s)

      start = Time.now

      success = run_command(cmd_args)

      if @image_optim.verbose
        seconds = Time.now - start
        $stderr << "#{success ? '✓' : '✗'} #{seconds}s #{cmd_args.shelljoin}\n"
      end

      success
    end

    # Run command defining environment, setting nice level, removing output and
    # reraising signal exception
    def run_command(cmd_args)
      args = if RUBY_VERSION < '1.9' || defined?(JRUBY_VERSION)
        %W[
          env PATH=#{@image_optim.env_path.shellescape}
          nice -n #{@image_optim.nice}
          #{cmd_args.shelljoin}
          > #{Path::NULL} 2>&1
        ].join(' ')
      else
        [
          {'PATH' => @image_optim.env_path},
          %W[nice -n #{@image_optim.nice}],
          cmd_args,
          {:out => Path::NULL, :err => Path::NULL},
        ].flatten
      end
      Cmd.run(*args)
    end
  end
end
