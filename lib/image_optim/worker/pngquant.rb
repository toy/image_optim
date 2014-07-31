require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    # http://pngquant.org/
    class Pngquant < Worker
      SPEED_OPTION =
      option(
        :speed, 3,
        'Speed/quality trade-off from 1 (brute-force) to 10 (fastest)'
      ) do |v|
        OptionHelpers.limit_with_range(v.to_i, 1..10)
      end

      # Always run first
      def run_order
        -1
      end

      def optimize(src, dst)
        ext = '-optimized.png'
        args = %W[--speed #{speed} --force --ext #{ext} -- #{src}]

        # Unfortunately, pngquant does not have an option for destination
        # filename So we use the ext option and move the optimized image to the
        # correct location.
        execute(:pngquant, *args) &&
          execute(:mv, output_path(src, ext), dst) &&
          optimized?(src, dst)
      end

      private
      def output_path(src, ext)
        src.dirname.join("#{File.basename(src, File.extname(src))}#{ext}")
      end
    end
  end
end
