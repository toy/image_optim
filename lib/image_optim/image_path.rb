require 'fspath'
require 'image_size'

require 'image_optim'

class ImageOptim
  class ImagePath < FSPath
    # Get temp path for this file with same extension
    def temp_path(*args, &block)
      ext = extname
      self.class.temp_file_path([basename(ext), ext], *args, &block)
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
      end
    end

    # Get format using ImageSize
    def format
      open{ |f| ImageSize.new(f) }.format
    end
  end
end
