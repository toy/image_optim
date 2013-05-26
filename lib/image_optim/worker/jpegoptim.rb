require 'image_optim/worker'

class ImageOptim
  class Worker
    class Jpegoptim < Worker
      option(:strip, :all, Array, 'List of extra markers to strip: comments, exif, iptc, icc or all') do |v|
        values = Array(v).map(&:to_s)
        known_values = %w[all comments exif iptc icc]
        unknown_values = values - known_values
        warn "Unknown markers for jpegoptim: #{unknown_values.join(', ')}" unless unknown_values.empty?
        values & known_values
      end

      option(:max_quality, 100, 'Maximum image quality factor 0..100'){ |v| OptionHelpers.limit_with_range(v.to_i, 0..100) }

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
