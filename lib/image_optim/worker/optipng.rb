require 'image_optim/worker'
require 'image_optim/option_helpers'
require 'image_optim/true_false_nil'

class ImageOptim
  class Worker
    # http://optipng.sourceforge.net/
    class Optipng < Worker
      LEVEL_OPTION =
      option(:level, 6, 'Optimization level preset: '\
          '`0` is least, '\
          '`7` is best') do |v|
        OptionHelpers.limit_with_range(v.to_i, 0..7)
      end

      INTERLACE_OPTION =
      option(:interlace, false, TrueFalseNil, 'Interlace: '\
          '`true` - interlace on, '\
          '`false` - interlace off, '\
          '`nil` - as is in original image') do |v|
        TrueFalseNil.convert(v)
      end

      STRIP_OPTION =
      option(:strip, true, 'Remove all auxiliary chunks'){ |v| !!v }

      def run_order
        -4
      end

      def optimize(src, dst)
        src.copy(dst)
        args = %W[
          -o #{level}
          -quiet
          --
          #{dst}
        ]
        args.unshift "-i#{interlace ? 1 : 0}" unless interlace.nil?
        if resolve_bin!(:optipng).version >= '0.7'
          args.unshift '-strip', 'all' if strip
        end
        execute(:optipng, *args) && optimized?(src, dst)
      end

      def optimized?(src, dst)
        interlace ? dst.size? : super
      end
    end
  end
end
