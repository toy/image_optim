require 'image_optim/image_path'

class ImageOptim
  # Holds optimized image with reference to original and its size
  class OptimizedPath < DelegateClass(ImagePath)
    def initialize(path, original_or_size = nil)
      path = ImagePath.convert(path)
      __setobj__(path)
      if original_or_size.is_a?(Integer)
        @original = path
        @original_size = original_or_size
      elsif original_or_size
        @original = ImagePath.convert(original_or_size)
        @original_size = @original.size
      end
    end

    # Original path, use original_size to get its size as original can be
    # overwritten
    attr_reader :original

    # Stored size of original
    attr_reader :original_size
  end
end
