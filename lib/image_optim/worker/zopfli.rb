require 'image_optim/worker'

class ImageOptim
  class Worker
    class Zopfli < Worker
      def image_formats
        [:png]
      end

      option(:splitlast, false, 'Do block splitting last instead of first'){ |v| !!v }

      option(:iterations, 15, 'Perform # iterations (default 15). More gives more compression but is slower. Examples: 10, 50, 1000') do |v|
        OptionHelpers.limit_with_range(v.to_i, 1..1000)
      end

      def optimize(src, dst)
        args = %W[-c #{"--splitlast" if splitlast} -i#{iterations} #{src} > #{dst}]
        execute(:zopfli, *args) && optimized?(src, dst)
      end
    end
  end
end
