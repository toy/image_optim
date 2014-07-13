require 'image_optim/image_path'

class ImageOptim
  class Handler
    attr_reader :result
    def initialize(original)
      unless original.respond_to?(:temp_path)
        fail ArgumentError, 'original should respond to temp_path'
      end

      @original = original
      @result = nil
    end

    def process
      @src ||= @original
      @dst ||= @original.temp_path

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
