require 'image_optim/worker'

class ImageOptim
  class Worker
    class Jpegtran < Worker
      # Copy all chunks or none (defaults to false)
      attr_reader :copy_chunks

      # Create progressive JPEG file (defaults to true)
      attr_reader :progressive

      def optimize(src, dst)
        args = %W[-optimize -outfile #{dst} #{src}]
        args.unshift '-copy', copy_chunks ? 'all' : 'none'
        args.unshift '-progressive' if progressive
        execute(:jpegtran, *args) && optimized?(src, dst)
      end

    private

      def parse_options(options)
        get_option!(options, :copy_chunks, false){ |v| !!v }
        get_option!(options, :progressive, true){ |v| !!v }
      end
    end
  end
end
