$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'image_optim'
require 'tempfile'

TEST_IMAGES = ImageOptim::ImagePath.new(__FILE__).dirname.glob('images/**/*.*')

Fixnum.class_eval do
  def in_range?(range)
    range.include?(self)
  end
end

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
  before do
    allow(ImageOptim::Config).to receive(:global).and_return({})
    allow(ImageOptim::Config).to receive(:local).and_return({})
  end

  describe 'worker' do
    base_options = Hash[ImageOptim::Worker.klasses.map do |klass|
      [klass.bin_sym, false]
    end]

    real_workers = ImageOptim::Worker.klasses.reject do |klass|
      klass.new({}).image_formats.empty?
    end

    real_workers.each do |worker_klass|
      describe worker_klass.bin_sym do
        it 'should optimize at least one test image' do
          options = base_options.merge(worker_klass.bin_sym => true)
          image_optim = ImageOptim.new(options)
          expect(TEST_IMAGES.any? do |original|
            image_optim.optimize_image(original.temp_copy)
          end).to be true
        end
      end
    end
  end

  describe 'isolated' do
    describe 'optimize' do
      TEST_IMAGES.each do |original|
        it "should optimize #{original}" do
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
      TEST_IMAGES.each do |original|
        it "should optimize #{original}" do
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
      TEST_IMAGES.each do |original|
        it "should optimize #{original}" do
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
      TEST_IMAGES.each do |original|
        it "should stop optimizing #{original}" do
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
    it 'should optimize' do
      copies = TEST_IMAGES.map(&:temp_copy)
      optimized_images = ImageOptim.optimize_images(copies)
      zipped = TEST_IMAGES.zip(copies, optimized_images)
      zipped.each do |original, copy, optimized_image|
        expect(optimized_image).to be_a(ImageOptim::ImagePath::Optimized)
        expect(optimized_image.size).to be_in_range(1...original.size)
        expect(optimized_image.read).not_to eq(original.read)
        expect(copy.read).to eq(original.read)
      end
    end

    it 'should optimize in place' do
      copies = TEST_IMAGES.map(&:temp_copy)
      ImageOptim.optimize_images!(copies)
      TEST_IMAGES.zip(copies).each do |original, copy|
        expect(copy.size).to be_in_range(1...original.size)
        expect(copy.read).not_to eq(original.read)
      end
    end

    it 'should optimize datas' do
      optimized_datas = ImageOptim.optimize_images_data(TEST_IMAGES.map(&:read))
      TEST_IMAGES.zip(optimized_datas).each do |original, optimized_data|
        expect(optimized_data).not_to be_nil

        expected_path = ImageOptim.optimize_image(original.temp_copy)
        expect(optimized_data).to eq(expected_path.open('rb', &:read))
      end
    end
  end

  describe 'unsupported' do
    let(:original){ ImageOptim::ImagePath.new(__FILE__) }

    it 'should ignore' do
      copy = original.temp_copy

      Tempfile.reset_init_count
      optimized_image = ImageOptim.optimize_image(copy)
      expect(Tempfile.init_count).to eq(0)
      expect(optimized_image).to be_nil
      expect(copy.read).to eq(original.read)
    end

    it 'should ignore in place' do
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

        it 'should ignore path' do
          path = FSPath.temp_file_path
          path.write(data)
          expect(ImageOptim.optimize_image(path)).to be_nil
        end

        it 'should ignore data' do
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
          it 'should optimize images and return array of results' do
            image_optim = ImageOptim.new
            dsts = srcs.map do |src|
              dst = "#{src}_"
              expect(image_optim).to receive(method).with(src).and_return(dst)
              dst
            end
            expect(image_optim.send(list_method, srcs)).to eq(dsts)
          end
        end

        describe 'given block' do
          it 'should optimize images, yield path and result for each and '\
              'return array of yield results' do
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
        expect(system(flatten_command)).to be_truthy
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
      nrmse = `#{nrmse_command}`[/\((\d+(\.\d+)?)\)/, 1]
      expect(nrmse).not_to be_nil
      expect(nrmse.to_f).to eq(0)
    end

    rotate_images.each do |image|
      it "should rotate and optimize #{image} losslessly" do
        check_lossless_optimization(rotated, ImageOptim.optimize_image(image))
      end
    end

    (TEST_IMAGES - rotate_images).each do |image|
      it "should optimize #{image} losslessly" do
        check_lossless_optimization(image, ImageOptim.optimize_image(image))
      end
    end
  end
end
