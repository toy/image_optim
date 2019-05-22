# frozen_string_literal: true

require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    # http://www.advsys.net/ken/util/pngout.htm
    class Pngout < Worker
      COPY_CHUNKS_OPTION =
      option(:copy_chunks, false, 'Copy optional chunks'){ |v| !!v }

      STRATEGY_OPTION =
      option(:strategy, 0, 'Strategy: '\
          '`0` - xtreme, '\
          '`1` - intense, '\
          '`2` - longest Match, '\
          '`3` - huffman Only, '\
          '`4` - uncompressed') do |v|
        OptionHelpers.limit_with_range(v.to_i, 0..4)
      end

      def run_order
        2
      end

      def optimize(src, dst)
        args = %W[
          -k#{copy_chunks ? 1 : 0}
          -s#{strategy}
          -q
          -y
          #{src}
          #{dst}
        ]
        execute(:pngout, *args) && optimized?(src, dst)
      rescue SignalException => e
        raise unless Signal.list.key(e.signo) == 'SEGV'
        raise unless resolve_bin!(:pngout).version <= '20150920'

        warn "pngout caused Segmentation fault for #{src}"
      end
    end
  end
end
