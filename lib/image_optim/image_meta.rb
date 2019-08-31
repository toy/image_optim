# frozen_string_literal: true

require 'image_size'

class ImageOptim
  # Getting format of image at path or as data
  module ImageMeta
    def self.format_for_path(path)
      is = ImageSize.path(path)
      is.format if is
    rescue ImageSize::FormatError => e
      warn "#{e} (detecting format of image at #{path})"
    end

    def self.format_for_data(data)
      is = ImageSize.new(data)
      is.format if is
    rescue ImageSize::FormatError => e
      warn "#{e} (detecting format of image data)"
    end
  end
end
