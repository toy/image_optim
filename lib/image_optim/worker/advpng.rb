require 'image_optim/worker'

class ImageOptim
  class Worker
    class Advpng < Worker
      # Compression level: 0 - don't compress, 1 - fast, 2 - normal, 3 - extra, 4 - extreme (defaults to 4)
      attr_reader :level

    private

      def parse_options(options)
        get_option!(options, :level, 4){ |v| limit_with_range(v.to_i, 0..4) }
      end

      def command_args(src, dst)
        src.copy(dst)
        %W[-#{level} -z -q -- #{dst}]
      end
    end
  end
end
