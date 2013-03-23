require 'image_optim/worker'

class ImageOptim
  class Worker
    class Pngout < Worker
      # Copy optional chunks (defaults to false)
      option(:copy_chunks, false){ |v| !!v }

      # Strategy: 0 - xtreme, 1 - intense, 2 - longest Match, 3 - huffman Only, 4 - uncompressed (defaults to 0)
      option(:strategy, 0){ |v| OptionHelpers.limit_with_range(v.to_i, 0..4) }

      # Always run first
      def run_order
        -1
      end

      def optimize(src, dst)
        args = %W[-k#{copy_chunks ? 1 : 0} -s#{strategy} -q -y #{src} #{dst}]
        execute(:pngout, *args) && optimized?(src, dst)
      end
    end
  end
end
