$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rspec'
require 'image_optim'
require 'tempfile'

TEST_IMAGES = (ImageOptim::ImagePath.new(__FILE__).dirname.relative_path_from(Dir.pwd) / 'images').glob('*')

Fixnum.class_eval do
  def in_range?(range)
    range.include?(self)
  end
end

Tempfile.class_eval do
  def self.init_count
    @@init_count
  end

  def self.reset_init_count
    @@init_count = 0
  end

  reset_init_count

  alias_method :initialize_orig, :initialize
  def initialize(*args, &block)
    @@init_count += 1
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
end
