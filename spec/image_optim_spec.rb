require 'spec_helper'
require 'image_optim'
require 'image_optim/cmd'
require 'tempfile'

Tempfile.class_eval do
  def self.init_count
    class_variable_get(:@@init_count)
  end

  def self.init_count=(value)
    class_variable_set(:@@init_count, value)
  end

  def self.reset_init_count
    self.init_count = 0
  end

  reset_init_count

  alias_method :initialize_orig, :initialize
  def initialize(*args, &block)
    self.class.init_count += 1
    initialize_orig(*args, &block)
  end
end

ImageOptim::ImagePath.class_eval do
  def temp_copy
    temp_path.tap{ |path| copy(path) }
  end
end

describe ImageOptim do
  test_images = ImageOptim::ImagePath.new(__FILE__).dirname.
    glob('images/**/*.*').freeze

  matcher :be_in_range do |expected|
    match{ |actual| expected.include?(actual) }
  end

  before do
    stub_const('Cmd', ImageOptim::Cmd)

    allow(ImageOptim::Config).to receive(:global).and_return({})
    allow(ImageOptim::Config).to receive(:local).and_return({})
  end

  describe 'workers' do
    it 'is ordered by run_order' do
      image_optim = ImageOptim.new
      original_klasses = ImageOptim::Worker.klasses
      formats = original_klasses.map do |klass|
        klass.new(image_optim, {}).image_formats
      end.flatten.uniq

      [
        original_klasses,
        original_klasses.reverse,
        original_klasses.shuffle,
      ].each do |klasses|
        expect(ImageOptim::Worker).to receive(:klasses).and_return(klasses)

        image_optim = ImageOptim.new

        formats.each do |format|
          path = ImageOptim::ImagePath.new("test.#{format}")
          expect(path).to receive(:format).and_return(format)

          workers = image_optim.workers_for_image(path)
          expect(workers).to eq(workers.sort_by.with_index do |worker, i|
            [worker.run_order, i]
          end)
        end
      end
    end
  end

  describe 'worker' do
    base_options = Hash[ImageOptim::Worker.klasses.map do |klass|
      [klass.bin_sym, false]
    end]

    ImageOptim::Worker.klasses.each do |worker_klass|
      describe worker_klass.bin_sym do
        it 'optimizes at least one test image' do
          options = base_options.merge(worker_klass.bin_sym => true)
          image_optim = ImageOptim.new(options)
          expect(test_images.any? do |original|
            image_optim.optimize_image(original.temp_copy)
          end).to be true
        end
      end
    end
  end

  describe 'isolated' do
    describe 'optimize' do
      test_images.each do |original|
        it "optimizes #{original}" do
          copy = original.temp_copy

          Tempfile.reset_init_count
          image_optim = ImageOptim.new
          optimized_image = image_optim.optimize_image(copy)
          expect(optimized_image).to be_a(ImageOptim::ImagePath::Optimized)
          expect(optimized_image.size).to be_in_range(1...original.size)
          expect(optimized_image.read).not_to eq(original.read)
          expect(copy.read).to eq(original.read)

          if image_optim.workers_for_image(original).length > 1
            expect(Tempfile.init_count).to be_in_range(1..2)
          else
            expect(Tempfile.init_count).to eq(1)
          end
        end
      end
    end

    describe 'optimize in place' do
      test_images.each do |original|
        it "optimizes #{original}" do
          copy = original.temp_copy

          Tempfile.reset_init_count
          image_optim = ImageOptim.new
          expect(image_optim.optimize_image!(copy)).to be_truthy
          expect(copy.size).to be_in_range(1...original.size)
          expect(copy.read).not_to eq(original.read)

          if image_optim.workers_for_image(original).length > 1
            expect(Tempfile.init_count).to be_in_range(2..3)
          else
            expect(Tempfile.init_count).to eq(2)
          end
        end
      end
    end

    describe 'optimize image data' do
      test_images.each do |original|
        it "optimizes #{original}" do
          image_optim = ImageOptim.new
          optimized_data = image_optim.optimize_image_data(original.read)
          expect(optimized_data).not_to be_nil

          expected_path = image_optim.optimize_image(original.temp_copy)
          expect(optimized_data).to eq(expected_path.open('rb', &:read))

          expect(image_optim.optimize_image_data(optimized_data)).to be_nil
        end
      end
    end

    describe 'stop optimizing' do
      test_images.each do |original|
        it "stops optimizing #{original}" do
          copy = original.temp_copy

          tries = 0
          10.times do
            tries += 1
            break unless ImageOptim.optimize_image!(copy)
          end
          expect(tries).to be_in_range(2...3)
        end
      end
    end
  end

  describe 'bunch' do
    it 'optimizes' do
      copies = test_images.map(&:temp_copy)
      results = ImageOptim.optimize_images(copies)
      zipped = test_images.zip(copies, results)
      zipped.each do |original, copy, result|
        expect(result[0]).to eq(copy)
        expect(result[1]).to be_a(ImageOptim::ImagePath::Optimized)
        expect(result[1].size).to be_in_range(1...original.size)
        expect(copy.read).to eq(original.read)
      end
    end

    it 'optimizes in place' do
      copies = test_images.map(&:temp_copy)
      results = ImageOptim.optimize_images!(copies)
      zipped = test_images.zip(copies, results)
      zipped.each do |original, copy, result|
        expect(result[0]).to eq(copy)
        expect(result[1]).to be_a(ImageOptim::ImagePath::Optimized)
        expect(copy.size).to be_in_range(1...original.size)
      end
    end

    it 'optimizes datas' do
      results = ImageOptim.optimize_images_data(test_images.map(&:read))
      zipped = test_images.zip(results)
      zipped.each do |original, result|
        expect(result[0]).to eq(original.read)
        expect(result[1]).to be_a(String)
        expect(result[1].size).to be_in_range(1...original.size)

        expected_path = ImageOptim.optimize_image(original.temp_copy)
        expect(result[1]).to eq(expected_path.open('rb', &:read))
      end
    end
  end

  describe 'unsupported' do
    let(:original){ ImageOptim::ImagePath.new(__FILE__) }

    it 'ignores' do
      copy = original.temp_copy

      Tempfile.reset_init_count
      optimized_image = ImageOptim.optimize_image(copy)
      expect(Tempfile.init_count).to eq(0)
      expect(optimized_image).to be_nil
      expect(copy.read).to eq(original.read)
    end

    it 'ignores in place' do
      copy = original.temp_copy

      Tempfile.reset_init_count
      expect(ImageOptim.optimize_image!(copy)).not_to be_truthy
      expect(Tempfile.init_count).to eq(0)
      expect(copy.read).to eq(original.read)
    end

    {
      :png => "\211PNG\r\n\032\n",
      :jpeg => "\377\330",
    }.each do |type, data|
      describe "broken #{type}" do
        before do
          expect(ImageOptim::ImageMeta).to receive(:warn)
        end

        it 'ignores path' do
          path = FSPath.temp_file_path
          path.write(data)
          expect(ImageOptim.optimize_image(path)).to be_nil
        end

        it 'ignores data' do
          expect(ImageOptim.optimize_image_data(data)).to be_nil
        end
      end
    end
  end

  describe 'optimize multiple' do
    let(:srcs){ ('a'..'z').to_a }

    %w[optimize_images optimize_images!].each do |list_method|
      describe list_method do
        method = list_method.sub('images', 'image')
        describe 'without block' do
          it 'optimizes images and returns array of results' do
            image_optim = ImageOptim.new
            dsts = srcs.map do |src|
              dst = "#{src}_"
              expect(image_optim).to receive(method).with(src).and_return(dst)
              dst
            end
            expect(image_optim.send(list_method, srcs)).to eq(srcs.zip(dsts))
          end
        end

        describe 'given block' do
          it 'optimizes images, yields path and result for each and '\
              'returns array of yield results' do
            image_optim = ImageOptim.new
            results = srcs.map do |src|
              dst = "#{src}_"
              expect(image_optim).to receive(method).with(src).and_return(dst)
              "#{src} #{dst}"
            end
            expect(image_optim.send(list_method, srcs) do |src, dst|
              "#{src} #{dst}"
            end).to eq(results)
          end
        end
      end
    end
  end

  describe 'losslessness' do
    images_dir = ImageOptim::ImagePath.new(__FILE__).dirname / 'images'
    rotated = images_dir / 'orient/original.jpg'
    rotate_images = images_dir.glob('orient/?.jpg')

    def flatten_animation(image)
      if image.format == :gif
        flattened = image.temp_path
        flatten_command = %W[
          convert
          #{image.to_s.shellescape}
          -coalesce
          -append
          #{flattened.to_s.shellescape}
        ].join(' ')
        expect(Cmd.run(flatten_command)).to be_truthy
        flattened
      else
        image
      end
    end

    def check_lossless_optimization(original, optimized)
      expect(optimized).not_to be_nil
      original = flatten_animation(original)
      optimized = flatten_animation(optimized)
      nrmse_command = %W[
        compare
        -metric RMSE
        #{original.to_s.shellescape}
        #{optimized.to_s.shellescape}
        /dev/null
        2>&1
      ].join(' ')
      nrmse = Cmd.capture(nrmse_command)[/\((\d+(\.\d+)?)\)/, 1]
      expect(nrmse).not_to be_nil
      expect(nrmse.to_f).to eq(0)
    end

    rotate_images.each do |image|
      it "rotates and optimizes #{image} losslessly" do
        check_lossless_optimization(rotated, ImageOptim.optimize_image(image))
      end
    end

    (test_images - rotate_images).each do |image|
      it "optimizes #{image} losslessly" do
        check_lossless_optimization(image, ImageOptim.optimize_image(image))
      end
    end
  end
end
