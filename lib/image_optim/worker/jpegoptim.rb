require 'image_optim/worker'

class ImageOptim
  class Worker
    class Jpegoptim < Worker
      # List of extra markers to strip: comments, exif, iptc, icc (defaults to 'all')
      option(:strip, :all) do |v|
        markers = Array(v).map(&:to_s)
        possible_markers = %w[all comments exif iptc icc]
        unknown_markers = markers - possible_markers
        warn "Unknown markers for jpegoptim: #{unknown_markers.join(', ')}" unless unknown_markers.empty?
        markers & possible_markers
      end

      # Maximum image quality factor (defaults to 100)
      option(:max_quality, 100){ |v| v.to_i }

      # Run first if max_quality < 100
      def run_order
        max_quality < 100 ? -1 : 0
      end

      def optimize(src, dst)
        src.copy(dst)
        args = %W[-q -- #{dst}]
        strip.each do |strip_marker|
          args.unshift "--strip-#{strip_marker}"
        end
        args.unshift "-m#{max_quality}" if max_quality < 100
        execute(:jpegoptim, *args) && optimized?(src, dst)
      end
    end
  end
end
