require 'image_optim/bin_not_found_error'
require 'thread'
require 'fspath'

class ImageOptim
  class BinResolver
    attr_reader :dir
    def initialize
      @bins = {}
      @lock = Mutex.new
    end

    def resolve!(bin)
      bin = bin.to_sym
      resolving(bin) do
        @bins[bin] = resolve?(bin)
      end
      @bins[bin] or raise BinNotFoundError, "`#{bin}` not found"
    end

    VENDOR_PATH = File.expand_path('../../../vendor', __FILE__)

    def env_path
      [dir, ENV['PATH'], VENDOR_PATH].compact.join(':')
    end

  private

    def resolving(bin)
      unless @bins.include?(bin)
        @lock.synchronize do
          unless @bins.include?(bin)
            yield
          end
        end
      end
    end

    def resolve?(bin)
      if path = ENV["#{bin}_bin".upcase]
        unless @dir
          @dir = FSPath.temp_dir
          at_exit{ FileUtils.remove_entry_secure @dir }
        end
        symlink = @dir / bin
        symlink.make_symlink(File.expand_path(path))
      end
      accessible?(bin)
    end

    def accessible?(bin)
      `env PATH=#{env_path.shellescape} which #{bin.to_s.shellescape}` != ''
    end
  end
end
