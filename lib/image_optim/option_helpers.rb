require 'image_optim'

class ImageOptim
  module OptionHelpers
    # Remove option from hash and run through block or return default
    def get_option!(options, name, default)
      value = default
      if options.has_key?(name)
        value = options.delete(name)
      end
      if block_given?
        value = yield(value)
      end
      instance_variable_set("@#{name}", value)
    end

    # Ensure number is in range
    def self.limit_with_range(number, range)
      if range.include?(number)
        number
      elsif number < range.first
        range.first
      elsif range.exclude_end?
        range.last - 1
      else
        range.last
      end
    end

    # Raise unless all options are deleted
    def assert_options_empty!(options)
      unless options.empty?
        raise ConfigurationError, "unknown options #{options.inspect} for #{self}"
      end
    end
  end
end
