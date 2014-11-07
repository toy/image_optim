require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    # https://github.com/danielgtaylor/jpeg-archive#jpeg-recompress
    class Jpegrecompress < Worker
      QUALITY_OPTION =
          option(:quality, 4, 'JPEG quality preset: '\
          '`0` - low, '\
          '`1` - medium, '\
          '`2` - high, '\
          '`3` - veryhigh, '\
          '`4` - lossless') do |v|
            OptionHelpers.limit_with_range(v.to_i, 0..4)
          end

      QUALITY_OPTIONS = [:low, :medium, :high, :veryhigh, :lossless]

      def used_bins
        QUALITY_OPTIONS[quality] == :lossless ? [] : [:'jpeg-recompress']
      end

      # Run first [-1]
      def run_order
        -1
      end

      def optimize(src, dst)
        quality_str = QUALITY_OPTIONS[quality]
        return false if quality_str == :lossless
        args = ['-q', quality_str, src, dst]
        execute(:'jpeg-recompress', *args) && optimized?(src, dst)
      end
    end
  end
end
