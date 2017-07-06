require 'image_optim/worker'
require 'exifr/jpeg'

class ImageOptim
  class Worker
    # http://www.sentex.net/~mwandel/jhead/
    #
    # Jhead internally uses jpegtran which should be on path
    class Jhead < Worker
      ORIENTED = 2..8 # not top-left

      # Works on jpegs
      def image_formats
        [:jpeg]
      end

      # Run first, while exif is still present
      def run_order
        -10
      end

      def used_bins
        [:jhead, :jpegtran]
      end

      def optimize(src, dst)
        return false unless oriented?(src)
        src.copy(dst)
        args = %W[
          -autorot
          #{dst}
        ]
        resolve_bin!(:jpegtran)
        execute(:jhead, *args) && dst.size?
      end

    private

      def oriented?(image)
        exif = EXIFR::JPEG.new(image.to_s)
        ORIENTED.include?(exif.orientation.to_i)
      end
    end
  end
end
