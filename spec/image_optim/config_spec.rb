$:.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/config'

class ImageOptim
  describe Config do
    before do
      Config.stub(:global => {}, :local => {})
    end

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

      it "should convert value to number" do
        config = Config.new({:threads => '616'})
        config.threads.should == 616
      end
    end

    describe "for_worker" do
      class Abc < Worker
        def image_formats; []; end
      end

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

    describe 'class methods' do
      before do
        Config.unstub(:global)
        Config.unstub(:local)
      end

      describe 'global' do
        it "should return empty hash for global config if it does not exists" do
          File.should_receive(:file?).with(Config::GLOBAL_CONFIG_PATH).and_return(false)
          Config.should_not_receive(:read)

          Config.global.should == {}
        end

        it "should read global config if it exists" do
          File.should_receive(:file?).with(Config::GLOBAL_CONFIG_PATH).and_return(true)
          Config.should_receive(:read).with(Config::GLOBAL_CONFIG_PATH).and_return({:config => true})

          Config.global.should == {:config => true}
        end
      end

      describe 'local' do
        it "should return empty hash for local config if it does not exists" do
          File.should_receive(:file?).with(Config::LOCAL_CONFIG_PATH).and_return(false)
          Config.should_not_receive(:read)

          Config.local.should == {}
        end

        it "should read local config if it exists" do
          File.should_receive(:file?).with(Config::LOCAL_CONFIG_PATH).and_return(true)
          Config.should_receive(:read).with(Config::LOCAL_CONFIG_PATH).and_return({:config => true})

          Config.local.should == {:config => true}
        end
      end

      describe 'read' do
        it "should return hash with deep symbolised keys from yaml file reader" do
          path = double(:path)
          YAML.should_receive(:load_file).with(path).and_return({'config' => {'this' => true}})

          Config.instance_eval{ read(path) }.should == {:config => {:this => true}}
        end

        it "should warn and return an empty hash if yaml file reader returns non hash" do
          path = double(:path)
          YAML.should_receive(:load_file).with(path).and_return([:config])
          Config.should_receive(:warn)

          Config.instance_eval{ read(path) }.should == {}
        end

        it "should warn and return an empty hash if yaml file reader raises exception" do
          path = double(:path)
          YAML.should_receive(:load_file).with(path).and_raise
          Config.should_receive(:warn)

          Config.instance_eval{ read(path) }.should == {}
        end
      end
    end

  end
end
