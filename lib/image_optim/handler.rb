require 'image_optim/path'

class ImageOptim
  # Handles processing of original to result using upto two temp files
  class Handler
    # Holds latest successful result
    attr_reader :result

    # original must respond to temp_path
    def initialize(image_optim, original)
      unless original.respond_to?(:temp_path)
        fail ArgumentError, 'original should respond to temp_path'
      end

      @cache_dir_mode = image_optim.cache_dir_mode
      @original = original
      @result = nil
    end

    # with no associated block, works as new. Otherwise creates instance and
    # passes it to block, runs cleanup and returns result of handler
    def self.for(image_optim, original)
      handler = new(image_optim, original)
      if block_given?
        begin
          yield handler
          handler.result
        ensure
          handler.cleanup
        end
      else
        handler
      end
    end

    # Yields two paths, one to latest successful result or original, second to
    # temp path
    def process
      @src ||= @original
      @dst ||= @original.temp_path

      FileUtils.chmod(@cache_dir_mode, @src) unless @cache_dir_mode.nil?
      FileUtils.chmod(@cache_dir_mode, @dst) unless @cache_dir_mode.nil?

      return unless yield @src, @dst
      @result = @dst
      if @src == @original
        @src, @dst = @dst, nil
      else
        @src, @dst = @dst, @src
      end
    end

    # Remove extra temp files
    def cleanup
      return unless @dst
      @dst.unlink
      @dst = nil
    end
  end
end
