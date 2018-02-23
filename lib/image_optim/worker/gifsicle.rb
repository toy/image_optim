require 'image_optim/worker'

class ImageOptim
  class Worker
    # http://www.lcdf.org/gifsicle/
    class Gifsicle < Worker
      # If interlace specified initialize one instance
      # Otherwise initialize two, one with interlace off and one with on
      def self.init(image_optim, options = {})
        return super if options.key?(:interlace)

        [false, true].map do |interlace|
          new(image_optim, options.merge(:interlace => interlace))
        end
      end

      ALLOW_LOSSY_OPTION =
      option(:allow_lossy, false, 'Allow lossy option (available only on '\
        'giflossy, fork of gifsicle'){ |v| !!v }

      INTERLACE_OPTION =
      option(:interlace, false, TrueFalseNil, 'Interlace: '\
          '`true` - interlace on, '\
          '`false` - interlace off, '\
          '`nil` - as is in original image '\
          '(defaults to running two instances, one with interlace off and '\
          'one with on)') do |v|
        TrueFalseNil.convert(v)
      end

      LEVEL_OPTION =
      option(:level, 3, 'Compression level: '\
          '`1` - light and fast, '\
          '`2` - normal, '\
          '`3` - heavy (slower)') do |v|
        OptionHelpers.limit_with_range(v.to_i, 1..3)
      end

      LOSSY_OPTION =
      option(:lossy, 0, 'lossy compression level (requires giflossy); '\
        'ignored in default/lossless mode. Value type is signed integer. '\
        'Low positive values produce better quality, while negative values '\
        'give extremely bad quality. Example values:'\
          '`0` - no lossy compression, '\
          '`20` - low level compression (low noise), '\
          '`1000` - high level of compression (high noise), '\
          '`-1` - max level of compression (max noise)') do |v, opt_def|
        if allow_lossy
          v.to_i
        else
          if v != opt_def.default
            warn "#{self.class.bin_sym} #{opt_def.name} #{v} ignored "\
                'in lossless mode'
          end
          0
        end
      end

      CAREFUL_OPTION =
      option(:careful, false, 'Avoid bugs with some software'){ |v| !!v }

      def optimize(src, dst)
        args = %W[
          --output=#{dst}
          --no-comments
          --no-names
          --same-delay
          --same-loopcount
          --no-warnings
          --
          #{src}
        ]

        if resolve_bin!(:gifsicle).version >= '1.85'
          args.unshift '--no-extensions', '--no-app-extensions'
        end

        unless interlace.nil?
          args.unshift interlace ? '--interlace' : '--no-interlace'
        end
        args.unshift '--careful' if careful
        args.unshift "--optimize=#{level}" if level
        args.unshift "--lossy=#{lossy}" unless lossy.zero?
        execute(:gifsicle, *args) && optimized?(src, dst)
      end
    end
  end
end
