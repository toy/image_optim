$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/image_path'

describe ImageOptim::ImagePath do
  ImagePath = ImageOptim::ImagePath

  describe 'convert' do
    it 'should return ImagePath for string' do
      path = 'a'

      expect(ImagePath.convert(path)).to be_a(ImageOptim::ImagePath)
      expect(ImagePath.convert(path)).to eq(ImageOptim::ImagePath.new(path))

      expect(ImagePath.convert(path)).not_to eq(path)
      expect(ImagePath.convert(path)).not_to be(path)
    end

    it 'should return ImagePath for Pathname' do
      pathname = Pathname.new('a')

      expect(ImagePath.convert(pathname)).to be_a(ImageOptim::ImagePath)
      expect(ImagePath.convert(pathname)).to eq(ImageOptim::ImagePath.new(pathname))

      expect(ImagePath.convert(pathname)).to eq(pathname)
      expect(ImagePath.convert(pathname)).not_to be(pathname)
    end

    it 'should return same instance for ImagePath' do
      image_path = ImageOptim::ImagePath.new('a')

      expect(ImagePath.convert(image_path)).to be_a(ImageOptim::ImagePath)
      expect(ImagePath.convert(image_path)).to eq(ImageOptim::ImagePath.new(image_path))

      expect(ImagePath.convert(image_path)).to eq(image_path)
      expect(ImagePath.convert(image_path)).to be(image_path)
    end
  end
end
