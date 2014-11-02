require 'image_optim/worker'

class ImageOptim
  class Worker
    # http://www.lcdf.org/gifsicle/
    class Gifsicle < Worker
      INTERLACE_OPTION =
      option(:interlace, false, TrueFalseNil, 'Interlace: '\
          '`true` - interlace on, '\
          '`false` - interlace off, '\
          '`nil` - as is in original image') do |v|
        TrueFalseNil.convert(v)
      end

      LEVEL_OPTION =
      option(:level, 3, 'Compression level: '\
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

        if resolve_bin!(:gifsicle).version >= '1.85'
          args.unshift('--no-extensions', '--no-app-extensions')
        end

        unless interlace.nil?
          args.unshift(interlace ? '--interlace' : '--no-interlace')
        end
        args.unshift('--careful') if careful
        args.unshift("--optimize=#{level}") if level
        execute(:gifsicle, *args) && optimized?(src, dst)
      end
    end
  end
end
