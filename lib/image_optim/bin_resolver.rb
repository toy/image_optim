require 'image_optim'

class ImageOptim
  class BinResolver
    attr_reader :dir
    def initialize
      @bins = {}
      @lock = Mutex.new
    end

    def resolve!(bin)
      bin = bin.to_sym
      unless @bins.include?(bin)
        @lock.synchronize do
          @bins[bin] = resolve?(bin) unless @bins.include?(bin)
        end
      end
      @bins[bin] or raise BinNotFoundError, "`#{bin}` not found"
    end

    VENDOR_PATH = File.expand_path('../../../vendor', __FILE__)

    def env_path
      "#{dir}:#{ENV['PATH']}:#{VENDOR_PATH}"
    end

  private

    def resolve?(bin)
      if path = ENV["#{bin}_bin".upcase]
        unless @dir
          @dir = FSPath.temp_dir
          at_exit{ FileUtils.remove_entry_secure @dir }
        end
        symlink = @dir / bin
        symlink.make_symlink(File.expand_path(path))

        accessible?(symlink)
      else
        accessible?(bin)
      end
    end

    def accessible?(bin)
      `env PATH=#{env_path.shellescape} which #{bin.to_s.shellescape}` != ''
    end
  end
end
