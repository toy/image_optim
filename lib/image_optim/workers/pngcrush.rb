require 'image_optim'

class ImageOptim
  class Pngcrush < Worker
    # List of chunks to remove or 'alla' or 'allb' (defaults to 'alla')
    attr_reader :chunks

    # Fix otherwise fatal conditions such as bad CRCs (defaults to false)
    attr_reader :fix

    # Brute force try all methods, very time-consuming and generally not worthwhile (defaults to false)
    attr_reader :brute

    # Always run first
    def run_first?
      true
    end

  private

    def parse_options(options)
      get_option!(options, :chunks, leave_color ? :allc : :alla){ |v| Array(v).map(&:to_s) }
      get_option!(options, :fix, false){ |v| !!v }
      get_option!(options, :brute, false){ |v| !!v }
    end

    def command_args(src, dst)
      args = %W[-reduce -cc -q -- #{src} #{dst}]
      if chunks == :allc
        args.unshift '-rem', 'allb'
        %w[gAMA cHRM sRGB iCCP].each do |chunk|
          args.unshift '-keep', chunk
        end
      else
        Array(chunks).each do |chunk|
          args.unshift '-rem', chunk
        end
      end
      args.unshift '-fix' if fix
      args.unshift '-brute' if brute
      args
    end
  end
end
