$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rspec'
require 'image_optim'

spec_dir = ImageOptim::ImagePath.new(__FILE__).dirname.relative_path_from(Dir.pwd)
image_dir = spec_dir / 'images'

def temp_copy_path(original)
  original.class.temp_dir do |dir|
    temp_path = dir / original.basename
    original.copy(temp_path)
    yield temp_path
  end
end

class Tempfile
  alias_method :initialize_orig, :initialize

  def initialize(*args, &block)
    self.class.initialize_called
    initialize_orig(*args, &block)
  end

  def self.initialize_called
    @@call_count ||= 0
    @@call_count += 1
  end

  def self.reset_call_count
    @@call_count = 0
  end

  def self.call_count
    @@call_count
  end
end

Fixnum.class_eval do
  def in_range?(range)
    range.include?(self)
  end
end

describe ImageOptim do
  image_dir.glob('*') do |original|
    describe "optimizing #{original}" do
      it "should optimize image" do
        temp_copy_path(original) do |unoptimized|
          Tempfile.reset_call_count
          image_optim = ImageOptim.new
          optimized = image_optim.optimize_image(unoptimized)
          optimized.should be_a(FSPath)
          unoptimized.read.should == original.read
          optimized.size.should > 0
          optimized.size.should < unoptimized.size
          optimized.read.should_not == unoptimized.read
          if image_optim.workers_for_image(unoptimized).length > 1
            Tempfile.call_count.should be_in_range(1..2)
          else
            Tempfile.call_count.should === 1
          end
        end
      end

      it "should optimize image in place" do
        temp_copy_path(original) do |path|
          Tempfile.reset_call_count
          image_optim = ImageOptim.new
          image_optim.optimize_image!(path).should be_true
          path.size.should > 0
          path.size.should < original.size
          path.read.should_not == original.read
          if image_optim.workers_for_image(path).length > 1
            Tempfile.call_count.should be_in_range(2..3)
          else
            Tempfile.call_count.should === 2
          end
        end
      end

      it "should stop optimizing" do
        temp_copy_path(original) do |unoptimized|
          count = (1..10).find do |i|
            unoptimized = ImageOptim.optimize_image(unoptimized)
            unoptimized.nil?
          end
          count.should >= 2
          count.should < 10
        end
      end
    end
  end

  describe "unsupported file" do
    let(:original){ ImageOptim::ImagePath.new(__FILE__) }

    it "should ignore" do
      temp_copy_path(original) do |unoptimized|
        Tempfile.reset_call_count
        optimized = ImageOptim.optimize_image(unoptimized)
        Tempfile.call_count.should == 0
        optimized.should be_nil
        unoptimized.read.should == original.read
      end
    end

    it "should ignore in place" do
      temp_copy_path(original) do |unoptimized|
        Tempfile.reset_call_count
        ImageOptim.optimize_image!(unoptimized).should_not be_true
        Tempfile.call_count.should == 0
        unoptimized.read.should == original.read
      end
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
      single_method = list_method.sub('images', 'image')
      describe "without block" do
        it "should optimize images and return array of results" do
          image_optim = ImageOptim.new
          dsts = []
          srcs.each do |src|
            dst = "#{src}_"
            image_optim.should_receive(single_method).with(src).and_return(dst)
            dsts << dst
          end
          image_optim.send(list_method, srcs).should == dsts
        end
      end

      describe "given block" do
        it "should optimize images, yield path and result for each and return array of yield results" do
          image_optim = ImageOptim.new
          results = []
          srcs.each do |src|
            dst = "#{src}_"
            image_optim.should_receive(single_method).with(src).and_return(dst)
            results << "#{src} #{dst}"
          end
          image_optim.send(list_method, srcs) do |src, dst|
            "#{src} #{dst}"
          end.should == results
        end
      end
    end
  end
end
