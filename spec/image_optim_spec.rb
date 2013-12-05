$:.unshift File.expand_path('../../lib', __FILE__)
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
  describe "isolated" do
    describe "optimize" do
      TEST_IMAGES.each do |original|
        it "should optimize #{original}" do
          copy = original.temp_copy

          Tempfile.reset_init_count
          image_optim = ImageOptim.new
          optimized_image = image_optim.optimize_image(copy)
          optimized_image.should be_a(ImageOptim::ImagePath)
          optimized_image.size.should be_in_range(1...original.size)
          optimized_image.read.should_not == original.read
          copy.read.should == original.read

          if image_optim.workers_for_image(original).length > 1
            Tempfile.init_count.should be_in_range(1..2)
          else
            Tempfile.init_count.should === 1
          end
        end
      end
    end

    describe "optimize in place" do
      TEST_IMAGES.each do |original|
        it "should optimize #{original}" do
          copy = original.temp_copy

          Tempfile.reset_init_count
          image_optim = ImageOptim.new
          image_optim.optimize_image!(copy).should be_true
          copy.size.should be_in_range(1...original.size)
          copy.read.should_not == original.read

          if image_optim.workers_for_image(original).length > 1
            Tempfile.init_count.should be_in_range(2..3)
          else
            Tempfile.init_count.should === 2
          end
        end
      end
    end

    describe "optimize image data" do
      TEST_IMAGES.each do |original|
        it "should optimize #{original}" do
          image_optim = ImageOptim.new
          optimized_data = image_optim.optimize_image_data(original.read)
          optimized_data.should == image_optim.optimize_image(original.temp_copy).read

          image_optim.optimize_image_data(optimized_data).should be_nil
        end
      end
    end

    describe "stop optimizing" do
      TEST_IMAGES.each do |original|
        it "should stop optimizing #{original}" do
          copy = original.temp_copy

          tries = 0
          10.times do
            tries += 1
            break unless ImageOptim.optimize_image!(copy)
          end
          tries.should be_in_range(2...3)
        end
      end
    end
  end

  describe "bunch" do
    it "should optimize" do
      copies = TEST_IMAGES.map(&:temp_copy)
      optimized_images = ImageOptim.optimize_images(copies)
      TEST_IMAGES.zip(copies, optimized_images).each do |original, copy, optimized_image|
        optimized_image.should be_a(ImageOptim::ImagePath)
        optimized_image.size.should be_in_range(1...original.size)
        optimized_image.read.should_not == original.read
        copy.read.should == original.read
      end
    end

    it "should optimize in place" do
      copies = TEST_IMAGES.map(&:temp_copy)
      ImageOptim.optimize_images!(copies)
      TEST_IMAGES.zip(copies).each do |original, copy|
        copy.size.should be_in_range(1...original.size)
        copy.read.should_not == original.read
      end
    end

    it "should optimize datas" do
      optimized_images_datas = ImageOptim.optimize_images_data(TEST_IMAGES.map(&:read))
      TEST_IMAGES.zip(optimized_images_datas).each do |original, optimized_image_data|
        optimized_image_data.should == ImageOptim.optimize_image(original.temp_copy).read
      end
    end
  end

  describe "unsupported" do
    let(:original){ ImageOptim::ImagePath.new(__FILE__) }

    it "should ignore" do
      copy = original.temp_copy

      Tempfile.reset_init_count
      optimized_image = ImageOptim.optimize_image(copy)
      Tempfile.init_count.should == 0
      optimized_image.should be_nil
      copy.read.should == original.read
    end

    it "should ignore in place" do
      copy = original.temp_copy

      Tempfile.reset_init_count
      ImageOptim.optimize_image!(copy).should_not be_true
      Tempfile.init_count.should == 0
      copy.read.should == original.read
    end
  end

  describe "optimize multiple" do
    let(:srcs){ ('a'..'z').to_a }

    before do
      srcs.each do |src|
        ImageOptim::ImagePath.should_receive(:new).with(src).and_return(src)
      end
    end

    %w[optimize_images optimize_images!].each do |list_method|
      describe list_method do
        single_method = list_method.sub('images', 'image')
        describe "without block" do
          it "should optimize images and return array of results" do
            image_optim = ImageOptim.new
            dsts = srcs.map do |src|
              dst = "#{src}_"
              image_optim.should_receive(single_method).with(src).and_return(dst)
              dst
            end
            image_optim.send(list_method, srcs).should == dsts
          end
        end

        describe "given block" do
          it "should optimize images, yield path and result for each and return array of yield results" do
            image_optim = ImageOptim.new
            results = srcs.map do |src|
              dst = "#{src}_"
              image_optim.should_receive(single_method).with(src).and_return(dst)
              "#{src} #{dst}"
            end
            image_optim.send(list_method, srcs) do |src, dst|
              "#{src} #{dst}"
            end.should == results
          end
        end
      end
    end
  end

  describe "auto orienting" do
    original = ImageOptim::ImagePath.new(__FILE__).dirname / 'images/orient/original.jpg'
    ImageOptim::ImagePath.new(__FILE__).dirname.glob('images/orient/?.jpg').each do |jpg|
      it "should rotate #{jpg}" do
        image_optim = ImageOptim.new
        oriented = image_optim.optimize_image(jpg)
        nrmse = `compare -metric RMSE #{original.to_s.shellescape} #{oriented.to_s.shellescape} /dev/null 2>&1`[/\((\d+(\.\d+)?)\)/, 1]
        nrmse.should_not be_nil
        nrmse.to_f.should be < 0.005
      end
    end
  end
end
