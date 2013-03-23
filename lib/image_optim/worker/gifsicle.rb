require 'image_optim/worker'

class ImageOptim
  class Worker
    class Gifsicle < Worker
      # Turn on interlacing (defaults to false)
      option(:interlace, false){ |v| !!v }

      def optimize(src, dst)
        args = %W[-o #{dst} -O3 --no-comments --no-names --same-delay --same-loopcount --no-warnings -- #{src}]
        args.unshift('-i') if interlace
        execute(:gifsicle, *args) && optimized?(src, dst)
      end
    end
  end
end
