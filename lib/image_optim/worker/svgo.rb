require 'image_optim/worker'

class ImageOptim
  class Worker
    # https://github.com/svg/svgo
    class Svgo < Worker
      def optimize(src, dst)
        args = %W[-i #{src} -o #{dst}]
        execute(:svgo, *args) && optimized?(src, dst)
      end
    end
  end
end
