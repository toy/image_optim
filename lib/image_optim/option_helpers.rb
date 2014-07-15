class ImageOptim
  # Helper methods for options
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
  end
end
