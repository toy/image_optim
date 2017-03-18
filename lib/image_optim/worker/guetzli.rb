require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    # https://github.com/google/guetzli/
    class Guetzli < Worker
      ALLOW_LOSSY_OPTION =
        option(:allow_lossy, false, 'Allow quality option'){ |v| !!v }

      QUALITY_OPTION =
      option(:quality, 100, 'JPEG quality `0`..`100`, ignored in '\
         'default/lossless mode') do |v, opt_def|
        if allow_lossy
          OptionHelpers.limit_with_range(v.to_i, 0..100)
        else
          if v != opt_def.default
            warn "#{self.class.bin_sym} #{opt_def.name} #{v} ignored " \
                 'in lossless mode'
          end
          opt_def.default
        end
      end

      def image_formats
        [:jpeg]
      end

      def run_order
        quality < 100 ? -1 : 0
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
