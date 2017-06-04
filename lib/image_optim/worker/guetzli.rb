require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    # https://github.com/google/guetzli/
    class Guetzli < Worker
      ALLOW_LOSSY_OPTION =
      option(:allow_lossy, false, 'Allow worker, it is always lossy'){ |v| !!v }

      # Initialize only if allow_lossy
      def self.init(image_optim, options = {})
        super if options[:allow_lossy]
      end

      # Disable this worker by default due to it being very memory intensive.
      def self.disabled_by_default
        true
      end

      QUALITY_OPTION =
      option(:quality, 100, 'JPEG quality `0`..`100`') do |v, opt_def|
        OptionHelpers.limit_with_range(v.to_i, 0..100)
      end

      def image_formats
        [:jpeg]
      end

      def run_order
        -3
      end

      def optimize(src, dst)
        src.copy(dst)
        args = %W[
          --quality #{quality}
          #{src}
          #{dst}
        ]
        execute(:guetzli, *args) && optimized?(src, dst)
      end
    end
  end
end
