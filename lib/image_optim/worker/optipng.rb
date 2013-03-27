require 'image_optim/worker'

class ImageOptim
  class Worker
    class Optipng < Worker
      option(:level, 6, 'Optimization level preset 0 is least, 7 is best'){ |v| OptionHelpers.limit_with_range(v.to_i, 0..7) }

      option(:interlace, false, TrueFalseNil, 'Interlace, true - interlace on, false - interlace off, nil - as is in original image') do |v|
        v && true
      end

      def optimize(src, dst)
        src.copy(dst)
        args = %W[-o#{level} -quiet -- #{dst}]
        args.unshift "-i#{interlace ? 1 : 0}" unless interlace.nil?
        execute(:optipng, *args) && optimized?(src, dst)
      end
    end
  end
end
