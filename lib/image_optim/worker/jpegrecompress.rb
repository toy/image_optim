require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    # https://github.com/danielgtaylor/jpeg-archive#jpeg-recompress
    class Jpegrecompress < Worker
      # Initialize only if allow_lossy
      def self.init(image_optim, options = {})
        super if options[:allow_lossy]
      end

      QUALITY_NAMES = [:low, :medium, :high, :veryhigh, :lossless]

      QUALITY_OPTION =
      option(:quality, 4, 'JPEG quality preset: '\
          '`0` - low, '\
          '`1` - medium, '\
          '`2` - high, '\
          '`3` - veryhigh, '\
          '`4` - lossless') do |v|
        OptionHelpers.limit_with_range(v.to_i, 0..4)
      end

      def used_bins
        QUALITY_NAMES[quality] == :lossless ? [] : [:'jpeg-recompress']
      end

      # Run first [-1]
      def run_order
        -5
      end

      def optimize(src, dst)
        quality_str = QUALITY_NAMES[quality]
        return false if quality_str == :lossless
        args = %W[
          --quality #{quality_str}
          --no-copy
          #{src}
          #{dst}
        ]
        execute(:'jpeg-recompress', *args) && optimized?(src, dst)
      end
    end
  end
end
