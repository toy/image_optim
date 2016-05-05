require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    # http://www.kokkonen.net/tjko/projects.html
    class Jpegoptim < Worker
      ALLOW_LOSSY_OPTION =
      option(:allow_lossy, false, 'Allow limiting maximum quality'){ |v| !!v }

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
          '`0`..`100`, ignored in default/lossless mode') do |v, opt_def|
        if allow_lossy
          OptionHelpers.limit_with_range(v.to_i, 0..100)
        else
          if v != opt_def.default
            warn "#{self.class.bin_sym} #{opt_def.name} #{v} ignored " \
                'in lossless mode'
          end
          opt_def.default
        end
      end

      # Run earlier if max_quality is less than 100
      def run_order
        max_quality < 100 ? -1 : 0
      end

      def optimize(src, dst)
        src.copy(dst)
        args = %W[
          --quiet
          --
          #{dst}
        ]
        strip.each do |strip_marker|
          args.unshift "--strip-#{strip_marker}"
        end
        args.unshift "--max=#{max_quality}" if max_quality < 100
        execute(:jpegoptim, *args) && optimized?(src, dst)
      end
    end
  end
end
