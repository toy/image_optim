# frozen_string_literal: true

require 'image_optim/worker'
require 'image_optim/option_helpers'
require 'image_optim/true_false_nil'

class ImageOptim
  class Worker
    # https://github.com/shssoichiro/oxipng
    class Oxipng < Worker
      LEVEL_OPTION =
      option(:level, 3, 'Optimization level preset: ' \
                        '`0` is least, ' \
                        '`6` is best') do |v|
        OptionHelpers.limit_with_range(v.to_i, 0..6)
      end

      INTERLACE_OPTION =
      option(:interlace, false, TrueFalseNil, 'Interlace: ' \
                                              '`true` - interlace on, ' \
                                              '`false` - interlace off, ' \
                                              '`nil` - as is in original image') do |v|
        TrueFalseNil.convert(v)
      end

      STRIP_OPTION =
      option(:strip, true, 'Remove all auxiliary chunks'){ |v| !!v }

      def run_order
        -4
      end

      def optimize(src, dst, options = {})
        src.copy(dst)
        args = %W[
          -o #{level}
          --quiet
          --
          #{dst}
        ]
        args.unshift "-i#{interlace ? 1 : 0}" unless interlace.nil?
        if strip
          args.unshift '--strip', 'all'
        end
        execute(:oxipng, args, options) && optimized?(src, dst)
      end

      def optimized?(src, dst)
        interlace ? dst.size? : super
      end
    end
  end
end
