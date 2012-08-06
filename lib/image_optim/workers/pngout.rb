require 'image_optim'

class ImageOptim
  class Pngout < Worker
    # Keep optional chunks (defaults to 0)
    attr_reader :keep_chunks

    # Strategy: 0 - xtreme, 1 - intense, 2 - longest Match, 3 - huffman Only, 4 - uncompressed (defaults to 0)
    attr_reader :strategy

    # Always run first
    def run_first?
      true
    end

  private

    def parse_options(options)
      get_option!(options, :keep_chunks, leave_color ? 'gAMA,cHRM,sRGB,iCCP' : 0){ |v| v ? 1 : 0 }
      get_option!(options, :strategy, 0){ |v| limit_with_range(v.to_i, 0..4) }
    end

    def command_args(src, dst)
      %W[-k#{keep_chunks} -s#{strategy} -q -y #{src} #{dst}]
    end
  end
end
