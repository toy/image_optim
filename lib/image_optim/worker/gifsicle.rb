require 'image_optim/worker'

class ImageOptim
  class Worker
    class Gifsicle < Worker
      # Turn on interlacing (defaults to false)
      attr_reader :interlace

      def optimize(src, dst)
        args = %W[-o #{dst} -O3 --no-comments --no-names --same-delay --same-loopcount --no-warnings -- #{src}]
        args.unshift('-i') if interlace
        execute(:gifsicle, *args) && optimized?(src, dst)
      end

    private

      def parse_options(options)
        get_option!(options, :interlace, false){ |v| !!v }
      end
    end
  end
end
