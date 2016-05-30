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

    # Copy file to dst, optionally preserving attributes
    #
    # See FileUtils.copy_file
    def copy(dst, preserve = false)
      FileUtils.copy_file(self, dst, preserve)
    end

    # Move file to dst: rename on same device, copy and unlink original
    # otherwise
    #
    # See FileUtils.mv
    def move(dst)
      FileUtils.move(self, dst)
    end

    # Copy metadata: uid, gid, mode, optionally atime and mtime
    #
    # Adapted from FileUtils::Entry_#copy_metadata by Minero Aoki
    def copy_metadata(dst, time = false)
      stat = lstat
      dst.utime(stat.atime, stat.mtime) if time
      begin
        dst.chown(stat.uid, stat.gid)
      rescue Errno::EPERM
        dst.chmod(stat.mode & 01777)
      else
        dst.chmod(stat.mode)
      end
    end

    # Atomic replace dst with self
    def replace(dst)
      dst = self.class.new(dst)
      dst.temp_path(dst.dirname) do |temp|
        move(temp)
        dst.copy_metadata(temp)
        temp.rename(dst.to_s)
      end
    end

    # Get format using ImageSize
    def format
      ImageMeta.format_for_path(self)
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
