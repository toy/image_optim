require 'image_optim/worker'

class ImageOptim
  class Worker
    class Jpegoptim < Worker
      # List of extra markers to strip: comments, exif, iptc, icc (defaults to 'all')
      attr_reader :strip

      # Maximum image quality factor (defaults to 100)
      attr_reader :max_quality

      # Run first if max_quality < 100
      def run_first?
        max_quality < 100
      end

    private

      def parse_options(options)
        get_option!(options, :strip, :all) do |v|
          markers = Array(v).map(&:to_s)
          possible_markers = %w[all comments exif iptc icc]
          unknown_markers = markers - possible_markers
          warn "Unknown markers for jpegoptim: #{unknown_markers.join(', ')}" unless unknown_markers.empty?
          markers & possible_markers
        end
        get_option!(options, :max_quality, 100){ |v| v.to_i }
      end

      def command_args(src, dst)
        src.copy(dst)
        args = %W[-q -- #{dst}]
        strip.each do |strip_marker|
          args.unshift "--strip-#{strip_marker}"
        end
        args.unshift "-m#{max_quality}" if max_quality < 100
        args
      end
    end
  end
end
