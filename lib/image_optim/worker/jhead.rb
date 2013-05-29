require 'image_optim/worker'
require 'exifr'

class ImageOptim
  class Worker
    class Jhead < Worker
      def image_formats
        [:jpeg]
      end

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
