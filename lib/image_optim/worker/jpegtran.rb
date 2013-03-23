require 'image_optim/worker'

class ImageOptim
  class Worker
    class Jpegtran < Worker
      # Copy all chunks or none (defaults to false)
      option(:copy_chunks, false){ |v| !!v }

      # Create progressive JPEG file (defaults to true)
      option(:progressive, true){ |v| !!v }

      # Use jpegtran through jpegrescan, ignore progressive option (defaults to true)
      option(:jpegrescan, false){ |v| !!v }

      def optimize(src, dst)
        if jpegrescan
          args = %W[#{src} #{dst}]
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
    end
  end
end
