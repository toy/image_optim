# frozen_string_literal: true

require 'image_optim/worker'

class ImageOptim
  class Worker
    # http://www.ijg.org/
    #
    # Uses jpegtran through jpegrescan if enabled, jpegrescan is vendored with
    # this gem
    class Jpegtran < Worker
      COPY_CHUNKS_OPTION =
      option(:copy_chunks, false, 'Copy all chunks'){ |v| !!v }

      PROGRESSIVE_OPTION =
      option(:progressive, true, 'Create progressive JPEG file'){ |v| !!v }

      JPEGRESCAN_OPTION =
      option(:jpegrescan, true, 'Use jpegtran through jpegrescan, '\
          'ignore progressive option'){ |v| !!v }

      def used_bins
        jpegrescan ? [:jpegtran, :jpegrescan] : [:jpegtran]
      end

      def optimize(src, dst)
        if jpegrescan
          args = %W[
            #{src}
            #{dst}
          ]
          args.unshift '-s' unless copy_chunks
          resolve_bin!(:jpegtran)
          execute(:jpegrescan, *args) && optimized?(src, dst)
        else
          args = %W[
            -optimize
            -outfile #{dst}
            #{src}
          ]
          args.unshift '-copy', (copy_chunks ? 'all' : 'none')
          args.unshift '-progressive' if progressive
          execute(:jpegtran, *args) && optimized?(src, dst)
        end
      end
    end
  end
end
