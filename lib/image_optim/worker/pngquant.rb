require 'image_optim/worker'
require 'image_optim/option_helpers'
require 'image_optim/non_negative_integer_range'

class ImageOptim
  class Worker
    # http://pngquant.org/
    class Pngquant < Worker
      QUALITY_OPTION =
      option(:quality, 100..100, NonNegativeIntegerRange, 'min..max - don\'t '\
          'save below min, use less colors below max (both in range `0..100`; '\
          'in yaml - `!ruby/range 0..100`), ignored in default/lossless '\
          'mode') do |v, opt_def|
        if allow_lossy
          min = OptionHelpers.limit_with_range(v.begin, 0..100)
          min..OptionHelpers.limit_with_range(v.end, min..100)
        else
          if v != opt_def.default
            warn "#{self.class.bin_sym} #{opt_def.name} #{v} ignored " \
                'in lossless mode'
          end
          opt_def.default
        end
      end

      SPEED_OPTION =
      option(:speed, 3, 'speed/quality trade-off: '\
          '`1` - slow, '\
          '`3` - default, '\
          '`11` - fast & rough') do |v|
        OptionHelpers.limit_with_range(v.to_i, 1..11)
      end

      # Always run first
      def run_order
        -5
      end

      def optimize(src, dst)
        args = %W[
          --quality=#{quality.begin}-#{quality.end}
          --speed=#{speed}
          --output=#{dst}
          --force
          --
          #{src}
        ]
        execute(:pngquant, *args) && optimized?(src, dst)
      end
    end
  end
end
