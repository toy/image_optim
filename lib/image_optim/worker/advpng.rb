require 'image_optim/worker'

class ImageOptim
  class Worker
    class Advpng < Worker
      option(:level, 4, 'Compression level: 0 - don\'t compress, 1 - fast, 2 - normal, 3 - extra, 4 - extreme') do |v|
        OptionHelpers.limit_with_range(v.to_i, 0..4)
      end

      def optimize(src, dst)
        src.copy(dst)
        args = %W[-#{level} -z -q -- #{dst}]
        execute(:advpng, *args) && optimized?(src, dst)
      end
    end
  end
end
