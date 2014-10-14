require 'image_optim/worker'

class ImageOptim
  class Worker
    # http://www.lcdf.org/gifsicle/
    class Gifsicle < Worker
      INTERLACE_OPTION =
      option(:interlace, false, 'Turn interlacing on'){ |v| !!v }

      def optimize(src, dst)
        args = %W[
          --output=#{dst}
          --optimize=3
          --no-comments
          --no-names
          --same-delay
          --same-loopcount
          --no-warnings
          --
          #{src}
        ]
        args.unshift('--interlace') if interlace
        execute(:gifsicle, *args) && optimized?(src, dst)
      end
    end
  end
end
