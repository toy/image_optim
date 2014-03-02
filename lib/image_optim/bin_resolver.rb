require 'thread'
require 'fspath'

class ImageOptim
  class BinNotFoundError < StandardError; end
  class BinResolver
    attr_reader :dir
    def initialize
      @bins = {}
      @lock = Mutex.new
    end

    def resolve!(name)
      name = name.to_sym
      resolving(name) do
        @bins[name] = resolve?(name)
      end
      @bins[name] or raise BinNotFoundError, "`#{name}` not found"
    end

    VENDOR_PATH = File.expand_path('../../../vendor', __FILE__)

    def env_path
      [dir, ENV['PATH'], VENDOR_PATH].compact.join(':')
    end

  private

    def resolving(name)
      unless @bins.include?(name)
        @lock.synchronize do
          unless @bins.include?(name)
            yield
          end
        end
      end
    end

    def resolve?(name)
      if path = ENV["#{name}_bin".upcase]
        unless @dir
          @dir = FSPath.temp_dir
          at_exit{ FileUtils.remove_entry_secure @dir }
        end
        symlink = @dir / name
        symlink.make_symlink(File.expand_path(path))
      end
      accessible?(name)
    end

    def accessible?(name)
      capture_output("which #{name.to_s.shellescape}") != ''
    end

    def capture_output(command)
      `env PATH=#{env_path.shellescape} #{command}`
    end
  end
end
