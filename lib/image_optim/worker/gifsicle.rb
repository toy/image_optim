require 'image_optim/worker'

class ImageOptim
  class Worker
    # http://www.lcdf.org/gifsicle/
    class Gifsicle < Worker
      INTERLACE_OPTION =
      option(:interlace, false, 'Turn interlacing on'){ |v| !!v }

      LEVEL_OPTION =
      option(:level, 3, 'Compression level: '\
          '`0` - Set unoptimazation flag, '\
          '`1` - stores only the changed portion of each image, '\
          '`2` - uses transparency to shrink the file further., '\
          '`3` - several optimization methods (slower, better results)') do |v|
        OptionHelpers.limit_with_range(v.to_i, 0..3)
      end

      def optimize(src, dst)
        args = %W[
          -o #{dst}
          --no-comments
          --no-names
          --same-delay
          --same-loopcount
          --no-warnings
          --careful
          --
          #{src}
        ]
        args.unshift('-i') if interlace
        args.unshift('-O#{level}') unless level == 0
        args.unshift('--unoptimize') if level == 0
        execute(:gifsicle, *args) && optimized?(src, dst)
      end
    end
  end
end
