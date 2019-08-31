# frozen_string_literal: true

require 'image_optim/worker'
require 'image_optim/option_helpers'
require 'image_optim/non_negative_integer_range'

class ImageOptim
  class Worker
    # http://pngquant.org/
    class Pngquant < Worker
      ALLOW_LOSSY_OPTION =
      option(:allow_lossy, false, 'Allow quality option'){ |v| !!v }

      MAX_COLORS_OPTION =
      option(:max_colors, 256, 'Maximum number of colors to use') do |v|
        OptionHelpers.limit_with_range(v.to_i, 2..256)
      end

      QUALITY_OPTION =
      option(:quality, '`100..100`, `0..100` in lossy mode',
             NonNegativeIntegerRange, 'min..max - don\'t '\
         'save below min, use less colors below max (both in range `0..100`; '\
         'in yaml - `!ruby/range 0..100`), ignored in default/lossless '\
         'mode') do |v, opt_def|
        if allow_lossy
          if v == opt_def.default
            0..100
          else
            min = OptionHelpers.limit_with_range(v.begin, 0..100)
            min..OptionHelpers.limit_with_range(v.end, min..100)
          end
        else
          if v != opt_def.default
            warn "#{self.class.bin_sym} #{opt_def.name} #{v} ignored " \
                'in lossless mode'
          end
          100..100
        end
      end

      SPEED_OPTION =
      option(:speed, 3, 'speed/quality trade-off: '\
          '`1` - slow, '\
          '`3` - default, '\
          '`11` - fast & rough') do |v|
        OptionHelpers.limit_with_range(v.to_i, 1..11)
      end

      def run_order
        -2
      end

      def optimize(src, dst)
        args = %W[
          --quality=#{quality.begin}-#{quality.end}
          --speed=#{speed}
          --output=#{dst}
          --force
          #{max_colors}
          --
          #{src}
        ]
        execute(:pngquant, *args) && optimized?(src, dst)
      end
    end
  end
end
