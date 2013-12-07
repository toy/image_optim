$:.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/config'

class ImageOptim
  describe Config do
    describe "assert_no_unused_options!" do
      it "should not raise when no unused options" do
        config = Config.new({})
        config.assert_no_unused_options!
      end

      it "should raise when there are unused options" do
        config = Config.new({:unused => true})
        proc {
          config.assert_no_unused_options!
        }.should raise_error(ConfigurationError)
      end
    end

    describe "nice" do
      it "should be 10 by default" do
        config = Config.new({})
        config.nice.should == 10
      end

      it "should be 0 if disabled" do
        config = Config.new({:nice => false})
        config.nice.should == 0
      end

      it "should convert value to number" do
        config = Config.new({:nice => '13'})
        config.nice.should == 13
      end
    end

    describe "threads" do
      it "should be processor_count by default" do
        config = Config.new({})
        config.stub(:processor_count).and_return(13)
        config.threads.should == 13
      end

      it "should be 1 if disabled" do
        config = Config.new({:threads => false})
        config.threads.should == 1
      end

      it "should convert value to number and limit to 1..16" do
        config = Config.new({:threads => '616'})
        config.threads.should == 16
      end
    end

    describe "for_worker" do
      class Abc < Worker; end

      it "should return empty hash by default" do
        config = Config.new({})
        config.for_worker(Abc).should == {}
      end

      it "should return passed hash" do
        config = Config.new({:abc => {:option => true}})
        config.for_worker(Abc).should == {:option => true}
      end

      it "should return passed false" do
        config = Config.new({:abc => false})
        config.for_worker(Abc).should == false
      end

      it "should raise on unknown optino" do
        config = Config.new({:abc => 13})
        proc {
          config.for_worker(Abc)
        }.should raise_error(ConfigurationError)
      end
    end
  end
end
