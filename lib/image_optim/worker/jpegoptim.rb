require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    class Jpegoptim < Worker
      STRIP_OPTION =
      option(:strip, :all, Array, 'List of extra markers to strip: '\
          '`:comments`, '\
          '`:exif`, '\
          '`:iptc`, '\
          '`:icc` or '\
          '`:all`') do |v|
        values = Array(v).map(&:to_s)
        known_values = %w[all comments exif iptc icc]
        unknown_values = values - known_values
        unless unknown_values.empty?
          warn "Unknown markers for jpegoptim: #{unknown_values.join(', ')}"
        end
        values & known_values
      end

      MAX_QUALITY_OPTION =
      option(:max_quality, 100, 'Maximum image quality factor '\
          '`0`..`100`') do |v|
        OptionHelpers.limit_with_range(v.to_i, 0..100)
      end

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
