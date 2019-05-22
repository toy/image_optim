# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/bin_resolver'
require 'image_optim/cmd'
require 'image_optim/path'

describe ImageOptim::BinResolver do
  def stub_env(key, value)
    allow(ENV).to receive(:[]).with(key).and_return(value)
  end

  before do
    stub_const('BinResolver', ImageOptim::BinResolver)
    stub_const('Bin', BinResolver::Bin)
    stub_const('SimpleVersion', BinResolver::SimpleVersion)
    stub_const('Cmd', ImageOptim::Cmd)

    allow(ENV).to receive(:[]).and_call_original
  end

  let(:image_optim){ double(:image_optim, :verbose => false, :pack => false) }
  let(:resolver){ BinResolver.new(image_optim) }

  describe '#full_path' do
    def full_path(name)
      resolver.instance_eval{ full_path(name) }
    end

    context 'when PATHEXT is not set' do
      it 'finds binary without ext in combined path' do
        stub_env 'PATH', %w[/a /b /c /d].join(File::PATH_SEPARATOR)
        stub_env 'PATHEXT', nil

        [
          [:file?,        '/a/abc', false],
          [:file?,        '/b/abc', true],
          [:executable?,  '/b/abc', false],
          [:file?,        '/c/abc', true],
          [:executable?,  '/c/abc', true],
        ].each do |method, path, result|
          allow(File).to receive(method).
            with(File.expand_path(path)).and_return(result)
        end

        expect(full_path('abc')).
          to eq(File.expand_path('/c/abc'))
      end
    end

    context 'when PATHEXT is set' do
      it 'finds binary with ext in combined path' do
        stub_env 'PATH', %w[/a /b].join(File::PATH_SEPARATOR)
        stub_env 'PATHEXT', '.com;.bat'

        [
          [:file?,        '/a/abc.com', false],
          [:file?,        '/a/abc.bat', true],
          [:executable?,  '/a/abc.bat', false],
          [:file?,        '/b/abc.com', true],
          [:executable?,  '/b/abc.com', true],
        ].each do |method, path, result|
          allow(File).to receive(method).
            with(File.expand_path(path)).and_return(result)
        end

        expect(full_path('abc')).
          to eq(File.expand_path('/b/abc.com'))
      end
    end

    it 'returns nil on failure' do
      stub_env 'PATH', ''
      expect(full_path('image_optim')).to be_nil
    end
  end

  it 'combines path in order dir, pack, path, vendor' do
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
    path = 'bin/the_optimizer'
    stub_env 'THE_OPTIMIZER_BIN', path
    tmpdir = double(:tmpdir, :to_str => 'tmpdir')
    symlink = double(:symlink)

    full_path = File.expand_path(path)
    allow(File).to receive(:exist?).with(full_path).and_return(true)
    allow(File).to receive(:file?).with(full_path).and_return(true)
    allow(File).to receive(:executable?).with(full_path).and_return(true)

    expect(FSPath).to receive(:temp_dir).
      once.and_return(tmpdir)
    expect(tmpdir).to receive(:/).
      with(:the_optimizer).once.and_return(symlink)
    expect(symlink).to receive(:make_symlink).
      with(File.expand_path(path)).once

    expect(resolver).not_to receive(:full_path)
    bin = double
    expect(Bin).to receive(:new).
      with(:the_optimizer, File.expand_path(path)).and_return(bin)
    expect(bin).to receive(:check!).once
    expect(bin).to receive(:check_fail!).exactly(5).times

    at_exit_blocks = []
    expect(resolver).to receive(:at_exit).once do |&block|
      at_exit_blocks.unshift(block)
    end

    5.times do
      resolver.resolve!(:the_optimizer)
    end
    expect(resolver.env_path).to eq([
      tmpdir,
      ENV['PATH'],
      BinResolver::VENDOR_PATH,
    ].join(File::PATH_SEPARATOR))

    expect(FileUtils).to receive(:remove_entry_secure).with(tmpdir)
    at_exit_blocks.each(&:call)
  end

  describe 'checking bin' do
    let(:path){ 'the_optimizer' }
    let(:exist?){ true }
    let(:file?){ true }
    let(:executable?){ true }

    before do
      stub_env 'THE_OPTIMIZER_BIN', path
      expect(FSPath).not_to receive(:temp_dir)
      expect(resolver).not_to receive(:at_exit)
      allow(File).to receive_messages(:exist? => exist?,
                                      :file? => file?,
                                      :executable? => executable?)
    end

    after do
      expect(resolver.env_path).to eq([
        ENV['PATH'],
        BinResolver::VENDOR_PATH,
      ].join(File::PATH_SEPARATOR))
    end

    def raises_error(error_message)
      5.times do
        expect do
          resolver.resolve!(:the_optimizer)
        end.to raise_error RuntimeError, /#{Regexp.escape(error_message)}/
      end
    end

    context 'presence' do
      let(:exist?){ false }

      it{ raises_error('doesn\'t exist') }
    end

    context 'been a file' do
      let(:file?){ false }

      it{ raises_error('is not a file') }
    end

    context 'been a file' do
      let(:executable?){ false }

      it{ raises_error('is not executable') }
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
        end.to raise_error Bin::UnknownVersion, %r{pngcrush at /bin/pngcrush}
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
        end.to raise_error Bin::BadVersion, /is known to produce broken pngs/
      end
    end

    it 'warns once on detection of problematic version' do
      stub_env 'ADVPNG_BIN', nil
      bin = Bin.new(:advpng, '/bin/advpng')

      expect(Bin).to receive(:new).and_return(bin)
      allow(bin).to receive(:version).and_return(SimpleVersion.new('none'))

      expect(bin).to receive(:warn).once.with(match(/is of unknown version/))

      5.times do
        resolver.resolve!(:pngcrush)
      end
    end
  end
end
