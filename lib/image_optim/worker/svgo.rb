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

      def optimize(src, dst)
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
        execute(:svgo, *args) && optimized?(src, dst)
      end
    end
  end
end
