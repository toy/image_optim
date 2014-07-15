require 'image_size'

class ImageOptim
  # Getting format of image at path or as data
  class ImageMeta
    def self.for_path(path)
      is = ImageSize.path(path)
      new(is.format)
    rescue ImageSize::FormatError => e
      warn "#{e} (detecting format of image at #{path})"
    end

    def self.for_data(data)
      is = ImageSize.new(data)
      new(is.format)
    rescue ImageSize::FormatError => e
      warn "#{e} (detecting format of image data)"
    end

    attr_reader :format
    def initialize(format)
      @format = format
    end
  end
end
