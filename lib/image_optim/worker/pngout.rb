require 'image_optim/worker'

class ImageOptim
  class Worker
    class Pngout < Worker
      # Copy optional chunks (defaults to false)
      attr_reader :copy_chunks

      # Strategy: 0 - xtreme, 1 - intense, 2 - longest Match, 3 - huffman Only, 4 - uncompressed (defaults to 0)
      attr_reader :strategy

      # Always run first
      def run_first?
        true
      end

    private

      def parse_options(options)
        get_option!(options, :copy_chunks, false){ |v| !!v }
        get_option!(options, :strategy, 0){ |v| limit_with_range(v.to_i, 0..4) }
      end

      def command_args(src, dst)
        %W[-k#{copy_chunks ? 1 : 0} -s#{strategy} -q -y #{src} #{dst}]
      end
    end
  end
end
