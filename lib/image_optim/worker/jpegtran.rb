require 'image_optim/worker'

class ImageOptim
  class Worker
    class Jpegtran < Worker
      # Copy all chunks or none (defaults to false)
      attr_reader :copy_chunks

      # Create progressive JPEG file (defaults to true)
      attr_reader :progressive

      # Use jpegtran through jpegrescan, ignore progressive option (defaults to true)
      attr_reader :jpegrescan

      def optimize(src, dst)
        if jpegrescan
          args = %W[#{dst} #{src}]
          args.unshift '-s' unless copy_chunks
          resolve_bin!(:jpegtran)
          execute(:jpegrescan, *args) && optimized?(src, dst)
        else
          args = %W[-optimize -outfile #{dst} #{src}]
          args.unshift '-copy', copy_chunks ? 'all' : 'none'
          args.unshift '-progressive' if progressive
          execute(:jpegtran, *args) && optimized?(src, dst)
        end
      end

    private

      def parse_options(options)
        get_option!(options, :copy_chunks, false){ |v| !!v }
        get_option!(options, :progressive, true){ |v| !!v }
        get_option!(options, :jpegrescan, false){ |v| !!v }
      end
    end
  end
end
