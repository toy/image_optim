require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    class Pngquant < Worker
      option(:speed, 3, 'Speed/quality trade-off from 1 (brute-force) to 10 (fastest)') do |v|
        OptionHelpers.limit_with_range(v.to_i, 1..10)
      end

      # Always run first
      def run_order
        -1
      end

      def optimize(src, dst)
        ext = '-optimized.png'
        args = %W[--speed #{speed} --force --ext #{ext} -- #{src}]

        # Unfortunately, pngquant does not have an option for destination filename.
        # So we use the ext option and move the optimized image to the correct location.
        execute(:pngquant, *args) &&
          execute(:mv, "#{src}#{ext}", dst) &&
          optimized?(src, dst)
      end
    end
  end
end
