require 'image_optim/image_path'

class ImageOptim
  # Handles processing of original to result using upto two temp files
  class Handler
    # Holds latest successful result
    attr_reader :result

    # original must respond to temp_path
    def initialize(original)
      unless original.respond_to?(:temp_path)
        fail ArgumentError, 'original should respond to temp_path'
      end

      @original = original
      @result = nil
    end

    # Yields two paths, one to latest successful result or original, second to
    # temp path
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
