$:.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/image_path'

describe ImageOptim::ImagePath do
  ImagePath = ImageOptim::ImagePath

  describe 'convert' do
    it 'should return ImagePath for string' do
      path = 'a'

      ImagePath.convert(path).should be_a(ImageOptim::ImagePath)
      ImagePath.convert(path).should eq(ImageOptim::ImagePath.new(path))

      ImagePath.convert(path).should_not eq(path)
      ImagePath.convert(path).should_not be(path)
    end

    it 'should return ImagePath for Pathname' do
      pathname = Pathname.new('a')

      ImagePath.convert(pathname).should be_a(ImageOptim::ImagePath)
      ImagePath.convert(pathname).should eq(ImageOptim::ImagePath.new(pathname))

      ImagePath.convert(pathname).should eq(pathname)
      ImagePath.convert(pathname).should_not be(pathname)
    end

    it 'should return same instance for ImagePath' do
      image_path = ImageOptim::ImagePath.new('a')

      ImagePath.convert(image_path).should be_a(ImageOptim::ImagePath)
      ImagePath.convert(image_path).should eq(ImageOptim::ImagePath.new(image_path))

      ImagePath.convert(image_path).should eq(image_path)
      ImagePath.convert(image_path).should be(image_path)
    end
  end
end
