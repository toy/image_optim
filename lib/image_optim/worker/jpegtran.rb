require 'image_optim/worker'

class ImageOptim
  class Worker
    class Jpegtran < Worker
      # Copy all chunks or none (defaults to false)
      attr_reader :copy

      # Create progressive JPEG file (defaults to true)
      attr_reader :progressive

    private

      def has_jpegrescan
        system("which -s jpegrescan")
      end

      def default_bin
        has_jpegrescan ? 'jpegrescan' : super
      end

      def parse_options(options)
        get_option!(options, :copy, false){ |v| !!v }
        get_option!(options, :progressive, true){ |v| !!v }
      end

      def command_args(src, dst)
        if has_jpegrescan
          args = %W[#{src} #{dst}]
        else
          args = %W[-optimize -outfile #{dst} #{src}]
          args.unshift '-copy', copy ? 'all' : 'none'
          args.unshift '-progressive' if progressive
        end
        args
      end
    end
  end
end
