# encoding: UTF-8

require 'image_optim/option_definition'
require 'image_optim/option_helpers'
require 'shellwords'

class ImageOptim
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
        @underscored_name ||= name.split('::').last.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
      end

      def option_definitions
        @option_definitions ||= []
      end

      def option(name, default, type, description = nil, &proc)
        attr_reader name
        option_definitions << OptionDefinition.new(name, default, type, description, &proc)
      end
    end

    # Configure (raises on extra options)
    def initialize(image_optim, options = {})
      @image_optim = image_optim
      self.class.option_definitions.each do |option_definition|
        value = if options.has_key?(option_definition.name)
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

    # List of formats which worker can optimize
    def image_formats
      format_from_name = self.class.name.downcase[/gif|jpeg|png|svg/]
      fail "#{self.class}: can't guess applicable format from worker name" unless format_from_name
      [format_from_name.to_sym]
    end

    # Ordering in list of workers
    def run_order
      0
    end

    def <=>(other)
      run_order <=> other.run_order
    end

    # Check if operation resulted in optimized file
    def optimized?(src, dst)
      dst.size? && dst.size < src.size
    end

  private

    def assert_no_unknown_options!(options)
      known_keys = self.class.option_definitions.map(&:name)
      unknown_options = options.reject{ |key, _value| known_keys.include?(key) }
      unless unknown_options.empty?
        fail ConfigurationError, "unknown options #{unknown_options.inspect} for #{self}"
      end
    end

    # Forward bin resolving to image_optim
    def resolve_bin!(bin)
      @image_optim.resolve_bin!(bin)
    end

    # Run command setting priority and hiding output
    def execute(bin, *arguments)
      command = build_command!(bin, *arguments)

      start = Time.now

      success = run_command(command)

      $stderr << "#{success ? '✓' : '✗'} #{Time.now - start}s #{command}\n" if @image_optim.verbose

      success
    end

    # Build command string
    def build_command!(bin, *arguments)
      resolve_bin!(bin)

      [bin, *arguments].map(&:to_s).shelljoin
    end

    # Run command defining environment, setting nice level, removing output and reraising signal exception
    def run_command(command)
      success = system "env PATH=#{@image_optim.env_path.shellescape} nice -n #{@image_optim.nice} #{command} > /dev/null 2>&1"

      if $?.signaled?
        unless defined?(JRUBY_VERSION) && $?.exitstatus == $?.termsig # jruby does not differ non zero exit status and signal number
          fail SignalException, $?.termsig
        end
      end

      success
    end
  end
end
