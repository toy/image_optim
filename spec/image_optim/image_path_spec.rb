require 'spec_helper'
require 'image_optim/image_path'

describe ImageOptim::ImagePath do
  before do
    stub_const('ImagePath', ImageOptim::ImagePath)
  end

  describe 'convert' do
    it 'returns ImagePath for string' do
      path = 'a'

      expect(ImagePath.convert(path)).to be_a(ImagePath)
      expect(ImagePath.convert(path)).to eq(ImagePath.new(path))

      expect(ImagePath.convert(path)).not_to eq(path)
      expect(ImagePath.convert(path)).not_to be(path)
    end

    it 'returns ImagePath for Pathname' do
      pathname = Pathname.new('a')

      expect(ImagePath.convert(pathname)).to be_a(ImagePath)
      expect(ImagePath.convert(pathname)).to eq(ImagePath.new(pathname))

      expect(ImagePath.convert(pathname)).to eq(pathname)
      expect(ImagePath.convert(pathname)).not_to be(pathname)
    end

    it 'returns same instance for ImagePath' do
      image_path = ImagePath.new('a')

      expect(ImagePath.convert(image_path)).to be_a(ImagePath)
      expect(ImagePath.convert(image_path)).to eq(ImagePath.new(image_path))

      expect(ImagePath.convert(image_path)).to eq(image_path)
      expect(ImagePath.convert(image_path)).to be(image_path)
    end
  end
end
