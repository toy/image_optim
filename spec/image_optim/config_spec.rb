$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/config'

describe ImageOptim::Config do
  Config = ImageOptim::Config

  before do
    allow(Config).to receive(:global).and_return({})
    allow(Config).to receive(:local).and_return({})
  end

  describe 'assert_no_unused_options!' do
    it 'should not raise when no unused options' do
      config = Config.new({})
      config.assert_no_unused_options!
    end

    it 'should raise when there are unused options' do
      config = Config.new(:unused => true)
      expect do
        config.assert_no_unused_options!
      end.to raise_error(ImageOptim::ConfigurationError)
    end
  end

  describe 'nice' do
    it 'should be 10 by default' do
      config = Config.new({})
      expect(config.nice).to eq(10)
    end

    it 'should be 0 if disabled' do
      config = Config.new(:nice => false)
      expect(config.nice).to eq(0)
    end

    it 'should convert value to number' do
      config = Config.new(:nice => '13')
      expect(config.nice).to eq(13)
    end
  end

  describe 'threads' do
    it 'should be processor_count by default' do
      config = Config.new({})
      allow(config).to receive(:processor_count).and_return(13)
      expect(config.threads).to eq(13)
    end

    it 'should be 1 if disabled' do
      config = Config.new(:threads => false)
      expect(config.threads).to eq(1)
    end

    it 'should convert value to number' do
      config = Config.new(:threads => '616')
      expect(config.threads).to eq(616)
    end
  end

  describe 'for_worker' do
    class Abc < ImageOptim::Worker
      def image_formats
        []
      end
    end

    it 'should return empty hash by default' do
      config = Config.new({})
      expect(config.for_worker(Abc)).to eq({})
    end

    it 'should return passed hash' do
      config = Config.new(:abc => {:option => true})
      expect(config.for_worker(Abc)).to eq(:option => true)
    end

    it 'should return passed false' do
      config = Config.new(:abc => false)
      expect(config.for_worker(Abc)).to eq(false)
    end

    it 'should raise on unknown optino' do
      config = Config.new(:abc => 13)
      expect do
        config.for_worker(Abc)
      end.to raise_error(ImageOptim::ConfigurationError)
    end
  end

  describe 'class methods' do
    before do
      allow(Config).to receive(:global).and_call_original
      allow(Config).to receive(:local).and_call_original
    end

    describe 'global' do
      it 'should return empty hash for global config if it does not exists' do
        expect(File).to receive(:file?).with(Config::GLOBAL_CONFIG_PATH).and_return(false)
        expect(Config).not_to receive(:read)

        expect(Config.global).to eq({})
      end

      it 'should read global config if it exists' do
        expect(File).to receive(:file?).with(Config::GLOBAL_CONFIG_PATH).and_return(true)
        expect(Config).to receive(:read).with(Config::GLOBAL_CONFIG_PATH).and_return(:config => true)

        expect(Config.global).to eq(:config => true)
      end
    end

    describe 'local' do
      it 'should return empty hash for local config if it does not exists' do
        expect(File).to receive(:file?).with(Config::LOCAL_CONFIG_PATH).and_return(false)
        expect(Config).not_to receive(:read)

        expect(Config.local).to eq({})
      end

      it 'should read local config if it exists' do
        expect(File).to receive(:file?).with(Config::LOCAL_CONFIG_PATH).and_return(true)
        expect(Config).to receive(:read).with(Config::LOCAL_CONFIG_PATH).and_return(:config => true)

        expect(Config.local).to eq(:config => true)
      end
    end

    describe 'read' do
      it 'should return hash with deep symbolised keys from yaml file reader' do
        path = double(:path)
        expect(YAML).to receive(:load_file).with(path).and_return('config' => {'this' => true})

        expect(Config.instance_eval{ read(path) }).to eq(:config => {:this => true})
      end

      it 'should warn and return an empty hash if yaml file reader returns non hash' do
        path = double(:path)
        expect(YAML).to receive(:load_file).with(path).and_return([:config])
        expect(Config).to receive(:warn)

        expect(Config.instance_eval{ read(path) }).to eq({})
      end

      it 'should warn and return an empty hash if yaml file reader raises exception' do
        path = double(:path)
        expect(YAML).to receive(:load_file).with(path).and_raise
        expect(Config).to receive(:warn)

        expect(Config.instance_eval{ read(path) }).to eq({})
      end
    end
  end
end
