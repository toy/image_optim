# frozen_string_literal: true

require 'image_optim/option_helpers'
require 'image_optim/worker'

class ImageOptim
  class Worker
    # https://github.com/svg/svgo
    class Svgo < Worker
      DISABLE_PLUGINS_OPTION =
      option(:disable_plugins, [], 'List of plugins to disable') do |v|
        Array(v).map(&:to_s)
      end

      ENABLE_PLUGINS_OPTION =
      option(:enable_plugins, [], 'List of plugins to enable') do |v|
        Array(v).map(&:to_s)
      end

      ALLOW_LOSSY_OPTION =
      option(:allow_lossy, false, 'Allow precision option'){ |v| !!v }

      PRECISION_OPTION =
      option(:precision, 3, 'Number of digits in the fractional part ' \
                            '`0`..`20`, ignored in default/lossless mode') \
                            do |v, opt_def|
        if allow_lossy
          OptionHelpers.limit_with_range(v.to_i, 0..20)
        else
          if v != opt_def.default
            warn "#{self.class.bin_sym} #{opt_def.name} #{v} ignored " \
                 'in default/lossless mode'
          end
          opt_def.default
        end
      end

      def optimize(src, dst, options = {})
        args = %W[
          --input #{src}
          --output #{dst}
        ]
        disable_plugins.each do |plugin_name|
          args.unshift "--disable=#{plugin_name}"
        end
        enable_plugins.each do |plugin_name|
          args.unshift "--enable=#{plugin_name}"
        end
        args.unshift "--precision=#{precision}" if allow_lossy
        execute(:svgo, args, options) && optimized?(src, dst)
      end
    end
  end
end
