require 'image_optim/worker'
require 'exifr'

class ImageOptim
  class Worker
    # http://www.sentex.net/~mwandel/jhead/
    #
    # Jhead internally uses jpegtran which should be on path
    class Jhead < Worker
      # Works on jpegs
      def image_formats
        [:jpeg]
      end

      # Run first [-10]
      def run_order
        -10
      end

      def optimize(src, dst)
        if (2..8).include?(EXIFR::JPEG.new(src.to_s).orientation.to_i)
          src.copy(dst)
          args = %W[-autorot #{dst}]
          resolve_bin!(:jpegtran)
          execute(:jhead, *args) && dst.size?
        else
          false
        end
      end
    end
  end
end
