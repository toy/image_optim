require 'spec_helper'
require 'image_optim/bin_resolver'
require 'image_optim/cmd'

describe ImageOptim::BinResolver do
  def stub_env(key, value)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with(key).and_return(value)
  end

  before do
    stub_const('BinResolver', ImageOptim::BinResolver)
    stub_const('Bin', BinResolver::Bin)
    stub_const('SimpleVersion', BinResolver::SimpleVersion)
    stub_const('Cmd', ImageOptim::Cmd)
  end

  let(:image_optim){ double(:image_optim, :verbose => false, :pack => false) }
  let(:resolver){ BinResolver.new(image_optim) }

  describe '#full_path' do
    def full_path(name)
      resolver.instance_eval{ full_path(name) }
    end

    def command_v(name)
      path = Cmd.capture("sh -c 'command -v #{name}' 2> /dev/null").strip
      path unless path.empty?
    end

    it 'finds binary in path' do
      stub_env 'PATH', 'bin'
      expect(full_path('image_optim')).
        to eq(File.expand_path('bin/image_optim'))
    end

    it 'finds bin in vendor' do
      stub_env 'PATH', nil
      expect(full_path('jpegrescan')).
        to eq(File.expand_path('vendor/jpegrescan'))
    end

    it 'finds bin in pack' do
      allow(image_optim).to receive(:pack).and_return(true)
      stub_const('ImageOptim::Pack', Class.new do
        def self.path
          'script'
        end
      end)

      stub_env 'PATH', nil
      expect(full_path('update_worker_options_in_readme')).
        to eq(File.expand_path('script/update_worker_options_in_readme'))
    end

    it 'works with different path separator' do
      stub_const('File::PATH_SEPARATOR', 'O_o')
      stub_env 'PATH', 'bin'
      expect(full_path('image_optim')).
        to eq(File.expand_path('bin/image_optim'))
    end

    it 'returns nil on failure' do
      stub_env 'PATH', 'lib'
      expect(full_path('image_optim')).to be_nil
    end

    %w[ls sh which bash image_optim does_not_exist].each do |name|
      it "returns same path as `command -v` for #{name}" do
        expect(full_path(name)).to eq(command_v(name))
      end
    end
  end

  it 'combines path in order dir:pack:path:vendor' do
    allow(image_optim).to receive(:pack).and_return(true)
    stub_const('ImageOptim::Pack', Class.new do
      def self.path
        'pack_path'
      end
    end)
    allow(resolver).to receive(:dir).and_return('temp_dir')

    expect(resolver.env_path).to eq([
      'temp_dir',
      'pack_path',
      ENV['PATH'],
      BinResolver::VENDOR_PATH,
    ].join(File::PATH_SEPARATOR))
  end

  it 'resolves bin in path and returns instance of Bin' do
    stub_env 'LS_BIN', nil
    expect(FSPath).not_to receive(:temp_dir)
    expect(resolver).to receive(:full_path).with(:ls).and_return('/bin/ls')
    bin = double
    expect(Bin).to receive(:new).with(:ls, '/bin/ls').and_return(bin)
    expect(bin).to receive(:check!).once
    expect(bin).to receive(:check_fail!).exactly(5).times

    5.times do
      expect(resolver.resolve!(:ls)).to eq(bin)
    end
    expect(resolver.env_path).to eq([
      ENV['PATH'],
      BinResolver::VENDOR_PATH,
    ].join(File::PATH_SEPARATOR))
  end

  it 'raises on failure to resolve bin' do
    stub_env 'LS_BIN', nil
    expect(FSPath).not_to receive(:temp_dir)
    expect(resolver).to receive(:full_path).with(:ls).and_return(nil)
    expect(Bin).not_to receive(:new)

    5.times do
      expect do
        resolver.resolve!(:ls)
      end.to raise_error BinResolver::BinNotFound
    end
    expect(resolver.env_path).to eq([
      ENV['PATH'],
      BinResolver::VENDOR_PATH,
    ].join(File::PATH_SEPARATOR))
  end

  it 'resolves bin specified in ENV' do
    path = 'bin/image_optim'
    stub_env 'IMAGE_OPTIM_BIN', path
    tmpdir = double(:tmpdir, :to_str => 'tmpdir')
    symlink = double(:symlink)

    expect(FSPath).to receive(:temp_dir).
      once.and_return(tmpdir)
    expect(tmpdir).to receive(:/).
      with(:image_optim).once.and_return(symlink)
    expect(symlink).to receive(:make_symlink).
      with(File.expand_path(path)).once

    expect(resolver).not_to receive(:full_path)
    bin = double
    expect(Bin).to receive(:new).
      with(:image_optim, File.expand_path(path)).and_return(bin)
    expect(bin).to receive(:check!).once
    expect(bin).to receive(:check_fail!).exactly(5).times

    at_exit_blocks = []
    expect(resolver).to receive(:at_exit).once do |&block|
      at_exit_blocks.unshift(block)
    end

    5.times do
      resolver.resolve!(:image_optim)
    end
    expect(resolver.env_path).to eq([
      tmpdir,
      ENV['PATH'],
      BinResolver::VENDOR_PATH,
    ].join(File::PATH_SEPARATOR))

    expect(FileUtils).to receive(:remove_entry_secure).with(tmpdir)
    at_exit_blocks.each(&:call)
  end

  {
    'some/path/does/not/exist' => 'doesn\'t exist',
    '.' => 'is not a file',
    __FILE__ => 'is not executable',
  }.each do |path, error_message|
    it "raises when bin specified in ENV #{error_message}" do
      stub_env 'IMAGE_OPTIM_BIN', path
      expect(FSPath).not_to receive(:temp_dir)
      expect(resolver).not_to receive(:at_exit)

      5.times do
        expect do
          resolver.resolve!(:image_optim)
        end.to raise_error RuntimeError, /#{Regexp.escape(error_message)}/
      end
      expect(resolver.env_path).to eq([
        ENV['PATH'],
        BinResolver::VENDOR_PATH,
      ].join(File::PATH_SEPARATOR))
    end
  end

  it 'resolves bin only once, but checks every time' do
    stub_env 'LS_BIN', nil
    expect(resolver).to receive(:full_path).once.with(:ls) do
      sleep 0.1
      '/bin/ls'
    end
    bin = double
    expect(Bin).to receive(:new).once.with(:ls, '/bin/ls').and_return(bin)

    count = 0
    mutex = Mutex.new
    allow(bin).to receive(:check!).once
    allow(bin).to receive(:check_fail!){ mutex.synchronize{ count += 1 } }

    Array.new(10) do
      Thread.new do
        resolver.resolve!(:ls)
      end
    end.each(&:join)

    expect(count).to eq(10)
  end

  describe 'checking version' do
    before do
      allow(resolver).to receive(:full_path){ |name| "/bin/#{name}" }
    end

    it 'raises every time if did not get bin version' do
      stub_env 'PNGCRUSH_BIN', nil
      bin = Bin.new(:pngcrush, '/bin/pngcrush')

      expect(Bin).to receive(:new).and_return(bin)
      allow(bin).to receive(:version).and_return(nil)

      5.times do
        expect do
          resolver.resolve!(:pngcrush)
        end.to raise_error Bin::UnknownVersion
      end
    end

    it 'raises every time on detection of misbehaving version' do
      stub_env 'PNGCRUSH_BIN', nil
      bin = Bin.new(:pngcrush, '/bin/pngcrush')

      expect(Bin).to receive(:new).and_return(bin)
      allow(bin).to receive(:version).and_return(SimpleVersion.new('1.7.60'))

      5.times do
        expect do
          resolver.resolve!(:pngcrush)
        end.to raise_error Bin::BadVersion
      end
    end

    it 'warns once on detection of problematic version' do
      stub_env 'ADVPNG_BIN', nil
      bin = Bin.new(:advpng, '/bin/advpng')

      expect(Bin).to receive(:new).and_return(bin)
      allow(bin).to receive(:version).and_return(SimpleVersion.new('1.15'))

      expect(bin).to receive(:warn).once

      5.times do
        resolver.resolve!(:pngcrush)
      end
    end
  end
end
