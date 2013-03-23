require 'image_optim/worker'

class ImageOptim
  class Worker
    class Advpng < Worker
      # Compression level: 0 - don't compress, 1 - fast, 2 - normal, 3 - extra, 4 - extreme (defaults to 4)
      option(:level, 4){ |v| OptionHelpers.limit_with_range(v.to_i, 0..4) }

      def optimize(src, dst)
        src.copy(dst)
        args = %W[-#{level} -z -q -- #{dst}]
        execute(:advpng, *args) && optimized?(src, dst)
      end
    end
  end
end
