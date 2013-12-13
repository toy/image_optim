require 'image_optim/configuration_error'

class ImageOptim
  module OptionHelpers
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
        raise ConfigurationError, "unused options #{options.inspect} for #{self}"
      end
    end
  end
end
