require 'fspath'
require 'image_optim/image_meta'

class ImageOptim
  # FSPath with additional helpful methods
  class ImagePath < FSPath
    # Holds optimized image with reference to original and its size
    class Optimized < DelegateClass(self)
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

    # Get temp path for this file with same extension
    def temp_path(*args, &block)
      ext = extname
      self.class.temp_file_path([basename(ext).to_s, ext], *args, &block)
    end

    # Copy file to dest preserving attributes
    def copy(dst)
      FileUtils.copy_file(self, dst, true)
    end

    # Atomic replace src with self
    def replace(src)
      src = self.class.new(src)
      src.temp_path(src.dirname) do |temp|
        src.copy(temp)
        temp.write(read)
        temp.rename(src.to_s)
        unlink
      end
    end

    # Get format using ImageSize
    def format
      image_meta = ImageMeta.for_path(self)
      image_meta && image_meta.format
    end

    # Read binary data
    def binread
      open('rb', &:read)
    end

    # Returns path if it is already an instance of this class otherwise new
    # instance
    def self.convert(path)
      path.is_a?(self) ? path : new(path)
    end
  end
end
