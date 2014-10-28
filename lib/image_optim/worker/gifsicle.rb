require 'image_optim/worker'

class ImageOptim
  class Worker
    # http://www.lcdf.org/gifsicle/
    class Gifsicle < Worker
      INTERLACE_OPTION =
      option(:interlace, false, 'Turn interlacing on'){ |v| !!v }

      LEVEL_OPTION =
      option(:level, 3, 'Compression level:'\
          '`1` - light and fast, '\
          '`2` - normal, '\
          '`3` - heavy (slower)') do |v|
        OptionHelpers.limit_with_range(v.to_i, 1..3)
      end

      CAREFUL_OPTION =
      option(:careful, false, 'Avoid bugs with some software'){ |v| !!v }

      def optimize(src, dst)
        args = %W[
          --output=#{dst}
          --no-comments
          --no-names
          --same-delay
          --same-loopcount
          --no-warnings
          --
          #{src}
        ]

        args.unshift('--interlace') if interlace
        args.unshift('--careful') if careful
        args.unshift("--optimize=#{level}") if level
        execute(:gifsicle, *args) && optimized?(src, dst)
      end
    end
  end
end
