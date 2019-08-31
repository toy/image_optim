# frozen_string_literal: true

require 'fspath'
require 'image_optim/image_meta'

class ImageOptim
  # FSPath with additional helpful methods
  class Path < FSPath
    NULL = if defined?(IO::NULL)
      IO::NULL
    else
      %w[/dev/null NUL: NUL nul NIL: NL:].find{ |dev| File.exist?(dev) }
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
        dst.chmod(stat.mode & 0o1777)
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
    def image_format
      ImageMeta.format_for_path(self)
    end

    # Returns path if it is already an instance of this class otherwise new
    # instance
    def self.convert(path)
      path.is_a?(self) ? path : new(path)
    end
  end
end
