require 'image_optim'

class ImageOptim
  class Gifsicle < Worker
    # Turn on interlacing (defaults to false)
    attr_reader :interlace

  private

    def parse_options(options)
      get_option!(options, :interlace, false){ |v| !!v }
    end

    def command_args(src, dst)
      args = %W[-o #{dst} -O3 --no-comments --no-names --same-delay --same-loopcount --no-warnings -- #{src}]
      args.unshift('-i') if interlace
      args
    end
  end
end
