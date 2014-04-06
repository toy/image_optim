require 'image_size'

class ImageOptim
  class ImageMeta
    def self.for_path(path)
      is = ImageSize.path(path)
      new(is.format)
    end

    def self.for_data(data)
      is = ImageSize.new(data)
      new(is.format)
    end

    attr_reader :format
    def initialize(format)
      @format = format
    end
  end
end
