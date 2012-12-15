require 'image_optim/worker'

class ImageOptim
  class Worker
    class Optipng < Worker
      # Optimization level preset 0..7 (0 is least, 7 is best, defaults to 6)
      attr_reader :level

      # Interlace, true - interlace on, false - interlace off, nil - as is in original image (defaults to false)
      attr_reader :interlace

    private

      def parse_options(options)
        get_option!(options, :level, 6){ |v| limit_with_range(v.to_i, 0..7) }
        get_option!(options, :interlace, false){ |v| v && true }
      end

      def command_args(src, dst)
        src.copy(dst)
        args = %W[-o#{level} -quiet -- #{dst}]
        unless interlace.nil?
          args.unshift "-i#{interlace ? 1 : 0}"
        end
        args
      end
    end
  end
end
