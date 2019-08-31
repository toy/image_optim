# frozen_string_literal: true

require 'image_optim/bin_resolver'
require 'image_optim/option_definition'

class ImageOptim
  class Worker
    # Class methods of ImageOptim::Worker
    module ClassMethods
      def self.extended(klass)
        klass.instance_variable_set(:@klasses, [])
      end

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
        @bin_sym ||=
          name.
          split('::').last. # get last part
          gsub(/([a-z])([A-Z])/, '\1_\2').downcase. # convert AbcDef to abc_def
          to_sym
      end

      def option_definitions
        @option_definitions ||= []
      end

      def option(name, default, type, description = nil, &proc)
        attr_reader name
        OptionDefinition.new(name, default, type, description, &proc).
          tap{ |option_definition| option_definitions << option_definition }
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
          messages = errors.map(&:to_s).uniq
          if image_optim.skip_missing_workers
            messages.each{ |message| warn message }
          else
            joint_message = ['Bin resolving errors:', *messages].join("\n")
            fail BinResolver::Error, joint_message
          end
        end

        resolved.sort_by.with_index{ |worker, i| [worker.run_order, i] }
      end

    private

      def init_all(image_optim, &options_proc)
        klasses.map do |klass|
          options = options_proc[klass]
          next if options[:disable]

          if !options.key?(:allow_lossy) && klass.method_defined?(:allow_lossy)
            options[:allow_lossy] = image_optim.allow_lossy
          end
          klass.init(image_optim, options)
        end.compact.flatten
      end
    end
  end
end
