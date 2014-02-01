require 'image_optim/worker'

class ImageOptim
  class Worker
    class Svgo < Worker
      def optimize(src, dst)
        args = %W[-i #{src} -o #{dst}]
        execute(:svgo, *args) && optimized?(src, dst)
      end
    end
  end
end
