require 'image_optim/worker'

class ImageOptim
  class Worker
    class Pngcrush < Worker
      # List of chunks to remove or 'alla' - all except tRNS/transparency or 'allb' - all except tRNS and gAMA/gamma (defaults to 'alla')
      option(:chunks, :alla){ |v| Array(v).map(&:to_s) }

      # Fix otherwise fatal conditions such as bad CRCs (defaults to false)
      option(:fix, false){ |v| !!v }

      # Brute force try all methods, very time-consuming and generally not worthwhile (defaults to false)
      option(:brute, false){ |v| !!v }

      # Always run first
      def run_order
        -1
      end

      def optimize(src, dst)
        args = %W[-reduce -cc -q -- #{src} #{dst}]
        chunks.each do |chunk|
          args.unshift '-rem', chunk
        end
        args.unshift '-fix' if fix
        args.unshift '-brute' if brute
        execute(:pngcrush, *args) && optimized?(src, dst)
      end
    end
  end
end
