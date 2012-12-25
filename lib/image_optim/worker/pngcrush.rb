require 'image_optim/worker'

class ImageOptim
  class Worker
    class Pngcrush < Worker
      # List of chunks to remove or 'alla' - all except tRNS/transparency or 'allb' - all except tRNS and gAMA/gamma (defaults to 'alla')
      attr_reader :chunks

      # Fix otherwise fatal conditions such as bad CRCs (defaults to false)
      attr_reader :fix

      # Brute force try all methods, very time-consuming and generally not worthwhile (defaults to false)
      attr_reader :brute

      # Always run first
      def run_order
        -1
      end

    private

      def parse_options(options)
        get_option!(options, :chunks, :alla){ |v| Array(v).map(&:to_s) }
        get_option!(options, :fix, false){ |v| !!v }
        get_option!(options, :brute, false){ |v| !!v }
      end

      def command_args(src, dst)
        args = %W[-reduce -cc -q -- #{src} #{dst}]
        chunks.each do |chunk|
          args.unshift '-rem', chunk
        end
        args.unshift '-fix' if fix
        args.unshift '-brute' if brute
        args
      end
    end
  end
end
