$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
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

def with_env(key, value)
  saved, ENV[key] = ENV[key], value
  yield
ensure
  ENV[key] = saved
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

  describe "resolve bin" do
    it "should resolve bin in path" do
      with_env 'LS_BIN', nil do
        image_optim = ImageOptim.new
        image_optim.should_receive(:bin_accessible?).with(:ls).once.and_return(true)
        FSPath.should_not_receive(:temp_dir)

        5.times do
          image_optim.resolve_bin!(:ls).should be_true
        end
      end
    end

    it "should resolve bin specified in ENV" do
      path = (FSPath(__FILE__).dirname / '../bin/image_optim').relative_path_from(Dir.pwd).to_s
      with_env 'IMAGE_OPTIM_BIN', path do
        tmpdir = double(:tmpdir)
        symlink = double(:symlink)

        image_optim = ImageOptim.new
        image_optim.should_receive(:bin_accessible?).with(symlink).once.and_return(true)
        FSPath.should_receive(:temp_dir).once.and_return(tmpdir)
        tmpdir.should_receive(:/).with(:image_optim).once.and_return(symlink)
        symlink.should_receive(:make_symlink).with(File.expand_path(path)).once

        at_exit_blocks = []
        image_optim.should_receive(:at_exit).twice do |&block|
          at_exit_blocks.unshift(block)
        end

        5.times do
          image_optim.resolve_bin!(:image_optim).should be_true
        end

        FileUtils.should_receive(:remove_entry_secure).with(tmpdir)
        symlink.should_receive(:unlink)
        at_exit_blocks.each(&:call)
      end
    end

    it "should raise on failure to resolve bin" do
      with_env 'SHOULD_NOT_EXIST_BIN', nil do
        image_optim = ImageOptim.new
        image_optim.should_receive(:bin_accessible?).with(:should_not_exist).once.and_return(false)
        FSPath.should_not_receive(:temp_dir)

        5.times do
          expect do
            image_optim.resolve_bin!(:should_not_exist)
          end.to raise_error ImageOptim::BinNotFoundError
        end
      end
    end

    it "should raise on failure to resolve bin specified in ENV" do
      path = (FSPath(__FILE__).dirname / '../bin/should_not_exist_bin').relative_path_from(Dir.pwd).to_s
      with_env 'SHOULD_NOT_EXIST_BIN', path do
        tmpdir = double(:tmpdir)
        symlink = double(:symlink)

        image_optim = ImageOptim.new
        image_optim.should_receive(:bin_accessible?).with(symlink).once.and_return(false)
        FSPath.should_receive(:temp_dir).once.and_return(tmpdir)
        tmpdir.should_receive(:/).with(:should_not_exist).once.and_return(symlink)
        symlink.should_receive(:make_symlink).with(File.expand_path(path)).once

        at_exit_blocks = []
        image_optim.should_receive(:at_exit).twice do |&block|
          at_exit_blocks.unshift(block)
        end

        5.times do
          expect do
            image_optim.resolve_bin!(:should_not_exist)
          end.to raise_error ImageOptim::BinNotFoundError
        end

        FileUtils.should_receive(:remove_entry_secure).with(tmpdir)
        symlink.should_receive(:unlink)
        at_exit_blocks.each(&:call)
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
