require 'spec_helper'
require 'image_optim'
require 'image_optim/cmd'
require 'tempfile'
require 'English'

describe ImageOptim do
  root_dir = ImageOptim::Path.new(__FILE__).dirname.dirname
  images_dir = root_dir / 'spec/images'
  test_images = images_dir.glob('**/*.*').freeze

  helpers = Module.new do
    def temp_copy(image)
      image.temp_path.tap{ |path| image.copy(path) }
    end
  end
  include helpers
  extend helpers

  before do
    stub_const('Cmd', ImageOptim::Cmd)
  end

  isolated_options_base = {:skip_missing_workers => false}
  ImageOptim::Worker.klasses.each do |klass|
    isolated_options_base[klass.bin_sym] = false
  end

  ImageOptim::Worker.klasses.each do |worker_klass|
    describe "#{worker_klass.bin_sym} worker" do
      it 'optimizes at least one test image' do
        options = isolated_options_base.merge(worker_klass.bin_sym => true)

        image_optim = ImageOptim.new(options)
        if Array(worker_klass.init(image_optim)).empty?
          image_optim = ImageOptim.new(options.merge(:allow_lossy => true))
        end

        expect(test_images.any? do |original|
          image_optim.optimize_image(temp_copy(original))
        end).to be true
      end
    end
  end

  describe '#optimize_image' do
    define :have_same_data_as do |expected|
      match{ |actual| actual.binread == expected.binread }
    end

    define :have_size do
      match(&:size?)
    end

    describe 'optimizing images' do
      rotated = images_dir / 'orient/original.jpg'
      rotate_images = images_dir.glob('orient/?.jpg')

      base_options = {:skip_missing_workers => false}
      [
        ['lossless', base_options, 0],
        ['lossy', base_options.merge(:allow_lossy => true), 0.001],
      ].each do |type, options, max_difference|
        it "does it #{type}" do
          image_optim = ImageOptim.new(options)
          copies = test_images.map{ |image| temp_copy(image) }
          pairs = image_optim.optimize_images(copies)
          test_images.zip(*pairs.transpose).each do |original, copy, optimized|
            expect(copy).to have_same_data_as(original)

            expect(optimized).not_to be_nil
            expect(optimized).to be_a(ImageOptim::OptimizedPath)
            expect(optimized).to have_size
            expect(optimized).to be_smaller_than(original)
            expect(optimized).not_to have_same_data_as(original)

            compare_to = rotate_images.include?(original) ? rotated : original
            expect(optimized).to be_similar_to(compare_to, max_difference)
          end
        end
      end
    end

    it 'ignores text file' do
      original = ImageOptim::Path.new(__FILE__)
      copy = temp_copy(original)

      expect(Tempfile).not_to receive(:new)
      optimized_image = ImageOptim.optimize_image(copy)
      expect(optimized_image).to be_nil
      expect(copy.read).to eq(original.read)
    end

    {
      :png => "\211PNG\r\n\032\n",
      :jpeg => "\377\330",
    }.each do |type, data|
      it "ingores broken #{type}" do
        path = FSPath.temp_file_path
        path.binwrite(data)
        expect(ImageOptim::ImageMeta).to receive(:warn)
        expect(ImageOptim.optimize_image(path)).to be_nil
      end
    end
  end

  describe '#optimize_image!' do
    it 'optimizes image and replaces original' do
      original = double
      optimized = double(:original_size => 12_345)
      optimized_wrap = double
      image_optim = ImageOptim.new

      allow(ImageOptim::Path).to receive(:convert).
        with(original).and_return(original)

      expect(image_optim).to receive(:optimize_image).
        with(original).and_return(optimized)
      expect(optimized).to receive(:replace).with(original)
      expect(ImageOptim::OptimizedPath).to receive(:new).
        with(original, 12_345).and_return(optimized_wrap)

      expect(image_optim.optimize_image!(original)).to eq(optimized_wrap)
    end

    it 'returns nil if optimization fails' do
      original = double
      image_optim = ImageOptim.new

      allow(ImageOptim::Path).to receive(:convert).
        with(original).and_return(original)

      expect(image_optim).to receive(:optimize_image).
        with(original).and_return(nil)
      expect(ImageOptim::OptimizedPath).not_to receive(:new)

      expect(image_optim.optimize_image!(original)).to eq(nil)
    end
  end

  describe '#optimize_image_data' do
    it 'create temp file, optimizes image and returns data' do
      data = double
      temp = double(:path => double)
      optimized = double
      optimized_data = double
      image_optim = ImageOptim.new

      allow(ImageOptim::ImageMeta).to receive(:format_for_data).
        with(data).and_return('xxx')

      expect(ImageOptim::Path).to receive(:temp_file).and_yield(temp)
      expect(temp).to receive(:binmode)
      expect(temp).to receive(:write).with(data)
      expect(temp).to receive(:close)
      expect(image_optim).to receive(:optimize_image).
        with(temp.path).and_return(optimized)
      expect(optimized).to receive(:binread).and_return(optimized_data)

      expect(image_optim.optimize_image_data(data)).to eq(optimized_data)
    end

    it 'returns nil if optimization fails' do
      data = double
      temp = double(:path => double)
      image_optim = ImageOptim.new

      allow(ImageOptim::ImageMeta).to receive(:format_for_data).
        with(data).and_return('xxx')

      expect(ImageOptim::Path).to receive(:temp_file).and_yield(temp)
      expect(temp).to receive(:binmode)
      expect(temp).to receive(:write).with(data)
      expect(temp).to receive(:close)
      expect(image_optim).to receive(:optimize_image).
        with(temp.path).and_return(nil)

      expect(image_optim.optimize_image_data(data)).to eq(nil)
    end

    it 'returns nil if format can\'t be detected' do
      data = double
      image_optim = ImageOptim.new

      allow(ImageOptim::ImageMeta).to receive(:format_for_data).
        with(data).and_return(nil)

      expect(ImageOptim::Path).not_to receive(:temp_file)
      expect(image_optim).not_to receive(:optimize_image)

      expect(image_optim.optimize_image_data(data)).to eq(nil)
    end
  end

  %w[
    optimize_images
    optimize_images!
    optimize_images_data
  ].each do |list_method|
    describe "##{list_method}" do
      method = list_method.sub('images', 'image')
      describe 'without block' do
        it 'optimizes images and returns array of results' do
          image_optim = ImageOptim.new
          results = test_images.map do |src|
            dst = double
            allow(image_optim).to receive(method).with(src).and_return(dst)
            [src, dst]
          end
          expect(image_optim.send(list_method, test_images)).to eq(results)
        end
      end

      describe 'given block' do
        it 'optimizes images, yields path and result for each and '\
            'returns array of yield results' do
          image_optim = ImageOptim.new
          results = test_images.map do |src|
            dst = double
            allow(image_optim).to receive(method).with(src).and_return(dst)
            [src, dst, :test]
          end
          expect(image_optim.send(list_method, test_images) do |src, dst|
            [src, dst, :test]
          end).to eq(results)
        end
      end
    end
  end

  %w[
    optimize_image
    optimize_image!
    optimize_image_data
    optimize_images
    optimize_images!
    optimize_images_data
  ].each do |method|
    describe ".#{method}" do
      it 'is checkable by respond_to?' do
        expect(ImageOptim).to respond_to(method)
      end

      it 'calls same method on a new ImageOptim instance' do
        image_optim = instance_double(ImageOptim)
        method_arg = double
        method_block = proc{ :x }

        allow(ImageOptim).to receive(:new).and_return(image_optim)
        expect(image_optim).to receive(method) do |arg, &block|
          expect(arg).to eq(method_arg)
          expect(block).to eq(method_block)
        end

        ImageOptim.send(method, method_arg, &method_block)
      end
    end
  end
end
