require 'image_optim/worker'

class ImageOptim
  class Worker
    class Pngcrush < Worker
      option(:chunks, :alla, Array, 'List of chunks to remove or \'alla\' - all except tRNS/transparency or '\
                                '\'allb\' - all except tRNS and gAMA/gamma'){ |v| Array(v).map(&:to_s) }

      option(:fix, false, 'Fix otherwise fatal conditions such as bad CRCs'){ |v| !!v }

      option(:brute, false, 'Brute force try all methods, very time-consuming and generally not worthwhile'){ |v| !!v }

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
