require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    # http://advancemame.sourceforge.net/doc-advpng.html
    class Advpng < Worker
      LEVEL_OPTION =
      option(:level, 4, 'Compression level: '\
          '`0` - don\'t compress, '\
          '`1` - fast, '\
          '`2` - normal, '\
          '`3` - extra, '\
          '`4` - extreme') do |v|
        OptionHelpers.limit_with_range(v.to_i, 0..4)
      end

      def run_order
        4
      end

      def optimize(src, dst)
        src.copy(dst)
        args = %W[
          --recompress
          -#{level}
          --quiet
          --
          #{dst}
        ]
        execute(:advpng, *args) && optimized?(src, dst)
      end
    end
  end
end
