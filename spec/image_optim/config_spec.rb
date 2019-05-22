# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/config'

describe ImageOptim::Config do
  before do
    stub_const('IOConfig', ImageOptim::Config)
  end

  describe '#assert_no_unused_options!' do
    before do
      allow(IOConfig).to receive(:read_options).and_return({})
    end

    it 'does not raise when no unused options' do
      config = IOConfig.new({})
      config.assert_no_unused_options!
    end

    it 'raises when there are unused options' do
      config = IOConfig.new(:unused => true)
      expect do
        config.assert_no_unused_options!
      end.to raise_error(ImageOptim::ConfigurationError)
    end
  end

  describe '#nice' do
    before do
      allow(IOConfig).to receive(:read_options).and_return({})
    end

    it 'is 10 by default' do
      config = IOConfig.new({})
      expect(config.nice).to eq(10)
    end

    it 'is 0 if disabled' do
      config = IOConfig.new(:nice => false)
      expect(config.nice).to eq(0)
    end

    it 'converts value to number' do
      config = IOConfig.new(:nice => '13')
      expect(config.nice).to eq(13)
    end
  end

  describe '#threads' do
    before do
      allow(IOConfig).to receive(:read_options).and_return({})
    end

    it 'is processor_count by default' do
      config = IOConfig.new({})
      allow(config).to receive(:processor_count).and_return(13)
      expect(config.threads).to eq(13)
    end

    it 'is 1 if disabled' do
      config = IOConfig.new(:threads => false)
      expect(config.threads).to eq(1)
    end

    it 'converts value to number' do
      config = IOConfig.new(:threads => '616')
      expect(config.threads).to eq(616)
    end
  end

  describe '#cache_dir' do
    before do
      allow(IOConfig).to receive(:read_options).and_return({})
    end

    it 'is nil by default' do
      config = IOConfig.new({})
      expect(config.cache_dir).to be nil
    end

    it 'is nil if set to the empty string' do
      config = IOConfig.new(:cache_dir => '')
      expect(config.cache_dir).to be nil
    end
  end

  describe '#cache_worker_digests' do
    before do
      allow(IOConfig).to receive(:read_options).and_return({})
    end

    it 'is false by default' do
      config = IOConfig.new({})
      expect(config.cache_worker_digests).to be false
    end
  end

  describe '#for_worker' do
    before do
      allow(IOConfig).to receive(:read_options).and_return({})
      stub_const('Abc', Class.new do
        def self.bin_sym
          :abc
        end
      end)
    end

    it 'returns empty hash by default' do
      config = IOConfig.new({})
      expect(config.for_worker(Abc)).to eq({})
    end

    it 'returns passed hash' do
      config = IOConfig.new(:abc => {:option => true})
      expect(config.for_worker(Abc)).to eq(:option => true)
    end

    it 'returns {:disable => true} for false' do
      config = IOConfig.new(:abc => false)
      expect(config.for_worker(Abc)).to eq(:disable => true)
    end

    it 'raises on unknown option' do
      config = IOConfig.new(:abc => 13)
      expect do
        config.for_worker(Abc)
      end.to raise_error(ImageOptim::ConfigurationError)
    end
  end

  describe '#initialize' do
    it 'reads options from default locations' do
      expect(IOConfig).to receive(:read_options).
        with(IOConfig::GLOBAL_PATH).and_return(:a => 1, :b => 2, :c => 3)
      expect(IOConfig).to receive(:read_options).
        with(IOConfig::LOCAL_PATH).and_return(:a => 10, :b => 20)

      config = IOConfig.new(:a => 100)
      expect(config.get!(:a)).to eq(100)
      expect(config.get!(:b)).to eq(20)
      expect(config.get!(:c)).to eq(3)
      config.assert_no_unused_options!
    end

    it 'does not read options with empty config_paths' do
      expect(IOConfig).not_to receive(:read_options)

      config = IOConfig.new(:config_paths => [])
      config.assert_no_unused_options!
    end

    it 'reads options from specified paths' do
      expect(IOConfig).to receive(:read_options).
        with('/etc/image_optim.yml').and_return(:a => 1, :b => 2, :c => 3)
      expect(IOConfig).to receive(:read_options).
        with('config/image_optim.yml').and_return(:a => 10, :b => 20)

      config = IOConfig.new(:a => 100, :config_paths => %w[
        /etc/image_optim.yml
        config/image_optim.yml
      ])
      expect(config.get!(:a)).to eq(100)
      expect(config.get!(:b)).to eq(20)
      expect(config.get!(:c)).to eq(3)
      config.assert_no_unused_options!
    end

    it 'converts config_paths to array' do
      expect(IOConfig).to receive(:read_options).
        with('config/image_optim.yml').and_return({})

      config = IOConfig.new(:config_paths => 'config/image_optim.yml')
      config.assert_no_unused_options!
    end
  end

  describe '.read_options' do
    let(:path){ double(:path) }
    let(:full_path){ double(:full_path) }

    it 'warns if expand path fails' do
      expect(IOConfig).to receive(:warn)
      expect(File).to receive(:expand_path).
        with(path).and_raise(ArgumentError)
      expect(File).not_to receive(:size?)

      expect(IOConfig.read_options(path)).to eq({})
    end

    it 'returns empty hash if path is not a file or is an empty file' do
      expect(IOConfig).not_to receive(:warn)
      expect(File).to receive(:expand_path).
        with(path).and_return(full_path)
      expect(File).to receive(:size?).
        with(full_path).and_return(false)

      expect(IOConfig.read_options(path)).to eq({})
    end

    it 'returns hash with deep symbolised keys from reader' do
      stringified = {'config' => {'this' => true}}
      symbolized = {:config => {:this => true}}

      expect(IOConfig).not_to receive(:warn)
      expect(File).to receive(:expand_path).
        with(path).and_return(full_path)
      expect(File).to receive(:size?).
        with(full_path).and_return(true)
      expect(YAML).to receive(:load_file).
        with(full_path).and_return(stringified)

      expect(IOConfig.read_options(path)).to eq(symbolized)
    end

    it 'warns and returns an empty hash if reader returns non hash' do
      expect(IOConfig).to receive(:warn)
      expect(File).to receive(:expand_path).
        with(path).and_return(full_path)
      expect(File).to receive(:size?).
        with(full_path).and_return(true)
      expect(YAML).to receive(:load_file).
        with(full_path).and_return([:config])

      expect(IOConfig.read_options(path)).to eq({})
    end

    it 'warns and returns an empty hash if reader raises exception' do
      expect(IOConfig).to receive(:warn)
      expect(File).to receive(:expand_path).
        with(path).and_return(full_path)
      expect(File).to receive(:size?).
        with(full_path).and_return(true)
      expect(YAML).to receive(:load_file).
        with(full_path).and_raise

      expect(IOConfig.read_options(path)).to eq({})
    end
  end
end
