# frozen_string_literal: true

require 'image_optim/worker'
require 'image_optim/option_helpers'

class ImageOptim
  class Worker
    # https://github.com/danielgtaylor/jpeg-archive#jpeg-recompress
    class Jpegrecompress < Worker
      ALLOW_LOSSY_OPTION =
      option(:allow_lossy, false, 'Allow worker, it is always lossy'){ |v| !!v }

      # Initialize only if allow_lossy
      def self.init(image_optim, options = {})
        super if options[:allow_lossy]
      end

      QUALITY_NAMES = [:low, :medium, :high, :veryhigh].freeze

      quality_names_desc = QUALITY_NAMES.each_with_index.map do |name, i|
        "`#{i}` - #{name}"
      end.join(', ')

      QUALITY_OPTION =
      option(:quality, 3, "JPEG quality preset: #{quality_names_desc}") do |v|
        OptionHelpers.limit_with_range(v.to_i, 0...QUALITY_NAMES.length)
      end

      METHOD_OPTION =
      option(:method, 'ssim', 'Comparison Metric: '\
          '`mpe` - Mean pixel error, '\
          '`ssim` - Structural similarity, '\
          '`ms-ssim` - Multi-scale structural similarity (slow!), '\
          '`smallfry` - Linear-weighted BBCQ-like (may be patented)') do |v, opt_def|
        if %w[mpe ssim ms-ssim smallfry].include? v
          v
        else
          warn "Unknown method for jpegrecompress: #{v}"
          opt_def.default
        end
      end

      def used_bins
        [:'jpeg-recompress']
      end

      # Run early as lossy worker
      def run_order
        -5
      end

      def optimize(src, dst)
        args = %W[
          --quality #{QUALITY_NAMES[quality]}
          --method #{method}
          --no-copy
          #{src}
          #{dst}
        ]
        execute(:'jpeg-recompress', *args) && optimized?(src, dst)
      end
    end
  end
end
