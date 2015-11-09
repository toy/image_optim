class ImageOptim
  # Hold information about an option
  class OptionDefinition
    attr_reader :name, :default, :type, :description, :proc

    def initialize(name, default, type_or_description, description = nil, &proc)
      if type_or_description.is_a?(Class)
        type = type_or_description
      else
        type, description = default.class, type_or_description
      end

      @name = name.to_sym
      @description = description.to_s
      @default, @type, @proc = default, type, proc
    end

    # Get value for worker from options
    def value(worker, options)
      value = options.key?(name) ? options[name] : default
      if proc
        if proc.arity == 2
          worker.instance_exec(value, self, &proc)
        else
          worker.instance_exec(value, &proc)
        end
      else
        value
      end
    end

    # Describe default value, returns string as is otherwise surrounds
    # inspected value with backticks
    def default_description
      default.is_a?(String) ? default : "`#{default.inspect}`"
    end
  end
end
