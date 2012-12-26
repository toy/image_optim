require 'image_optim/worker'

class ImageOptim
  class Worker
    class Advpng < Worker
      # Compression level: 0 - don't compress, 1 - fast, 2 - normal, 3 - extra, 4 - extreme (defaults to 4)
      attr_reader :level

      def optimize(src, dst)
        src.copy(dst)
        args = %W[-#{level} -z -q -- #{dst}]
        execute(:advpng, *args) && optimized?(src, dst)
      end

    private

      def parse_options(options)
        get_option!(options, :level, 4){ |v| limit_with_range(v.to_i, 0..4) }
      end
    end
  end
end
