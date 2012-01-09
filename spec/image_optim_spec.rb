$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rspec'
require 'image_optim'

spec_dir = ImageOptim::ImagePath.new(__FILE__).dirname.relative_path_from(Dir.pwd)
image_dir = spec_dir / 'images'

def temp_copy_path(original)
  original.class.temp_dir do |dir|
    temp_path = dir / original.basename
    begin
      original.copy(temp_path)
      yield temp_path
    ensure
      temp_path.unlink if temp_path.exist?
    end
  end
end

describe ImageOptim do
  image_dir.glob('*') do |original|
    describe "optimizing #{original}" do
      it "should optimize image" do
        temp_copy_path(original) do |unoptimized|
          optimized = ImageOptim.optimize_image(unoptimized)
          optimized.should be_a(FSPath)
          unoptimized.read.should == original.read
          optimized.size.should > 0
          optimized.size.should < unoptimized.size
          optimized.read.should_not == unoptimized.read
        end
      end

      it "should optimize image in place" do
        temp_copy_path(original) do |path|
          ImageOptim.optimize_image!(path).should be_true
          path.size.should > 0
          path.size.should < original.size
          path.read.should_not == original.read
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
        optimized = ImageOptim.optimize_image(unoptimized)
        optimized.should be_nil
        unoptimized.read.should == original.read
      end
    end

    it "should ignore in place" do
      temp_copy_path(original) do |unoptimized|
        ImageOptim.optimize_image!(unoptimized).should_not be_true
        unoptimized.read.should == original.read
      end
    end
  end
end
