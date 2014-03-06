require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    class Pngquant < Worker
      option(:quality, 80 , "don't save below min, use less colors below max (0-100)") do |v|
        OptionHelpers.limit_with_range(v.to_i, 0..100)
      end

      option(:speed, 1 , 'speed/quality trade-off. 1=slow, 3=default, 11=fast & rough') do |v|
        OptionHelpers.limit_with_range(v.to_i, 1..11)
      end

      # Always run first
      def run_order
        -1
      end

      def optimize(src, dst)
        args = %W[--quality=#{quality} --speed=#{speed} --ext=-min.png #{src}]
        mv_args = %W[#{src}-min.png #{dst}]
        execute(:pngquant, *args) &&
        execute(:mv, *mv_args) &&
        optimized?(src, dst)
      end
    end
  end
end
