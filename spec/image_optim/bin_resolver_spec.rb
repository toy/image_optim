$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/bin_resolver'

def with_env(key, value)
  saved, ENV[key] = ENV[key], value
  yield
ensure
  ENV[key] = saved
end

describe ImageOptim::BinResolver do
  BinResolver = ImageOptim::BinResolver
  Bin = BinResolver::Bin
  SimpleVersion = BinResolver::SimpleVersion

  let(:image_optim){ double(:image_optim, :verbose => false) }
  let(:resolver){ BinResolver.new(image_optim) }

  describe :full_path do
    def full_path(name)
      resolver.instance_eval{ full_path(name) }
    end

    def command_v(name)
      path = `sh -c 'command -v #{name}' 2> /dev/null`.strip
      path unless path.empty?
    end

    it 'should find binary in path' do
      with_env 'PATH', 'bin' do
        expect(full_path('image_optim')).
          to eq(File.expand_path('bin/image_optim'))
      end
    end

    it 'should return nil on failure' do
      with_env 'PATH', 'lib' do
        expect(full_path('image_optim')).to be_nil
      end
    end

    %w[ls sh which bash image_optim should_not_exist].each do |name|
      it "should return same path as `command -v` for #{name}" do
        expect(full_path(name)).to eq(command_v(name))
      end
    end
  end

  it 'should resolve bin in path' do
    with_env 'LS_BIN', nil do
      expect(FSPath).not_to receive(:temp_dir)
      expect(resolver).to receive(:full_path).with(:ls).and_return('/bin/ls')
      bin = double
      expect(Bin).to receive(:new).with(:ls, '/bin/ls').and_return(bin)
      expect(bin).to receive(:check!).exactly(5).times

      5.times do
        resolver.resolve!(:ls)
      end
      expect(resolver.env_path).to eq([
        ENV['PATH'],
        BinResolver::VENDOR_PATH,
      ].join(':'))
    end
  end

  it 'should raise on failure to resolve bin' do
    with_env 'LS_BIN', nil do
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
      ].join(':'))
    end
  end

  it 'should resolve bin specified in ENV' do
    path = 'bin/image_optim'
    with_env 'IMAGE_OPTIM_BIN', path do
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
      expect(bin).to receive(:check!).exactly(5).times

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
      ].join(':'))

      expect(FileUtils).to receive(:remove_entry_secure).with(tmpdir)
      at_exit_blocks.each(&:call)
    end
  end

  {
    'some/path/should_not_exist_bin' => 'doesn\'t exist',
    '.' => 'is not a file',
    __FILE__ => 'is not executable',
  }.each do |path, error_message|
    it "should raise when bin specified in ENV #{error_message}" do
      with_env 'IMAGE_OPTIM_BIN', path do
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
        ].join(':'))
      end
    end
  end

  it 'should resolve bin only once, but check every time' do
    with_env 'LS_BIN', nil do
      expect(resolver).to receive(:full_path).once.with(:ls) do
        sleep 0.1
        '/bin/ls'
      end
      bin = double
      expect(Bin).to receive(:new).once.with(:ls, '/bin/ls').and_return(bin)

      check_count = 0
      mutex = Mutex.new
      allow(bin).to receive(:check!){ mutex.synchronize{ check_count += 1 } }

      10.times.map do
        Thread.new do
          resolver.resolve!(:ls)
        end
      end.each(&:join)

      expect(check_count).to eq(10)
    end
  end

  it 'should raise if did not got bin version' do
    bin = Bin.new(:pngcrush, '/bin/pngcrush')
    allow(bin).to receive(:version).and_return(nil)

    5.times do
      expect do
        bin.check!
      end.to raise_error Bin::BadVersion
    end
  end

  it 'should raise on detection of problematic version' do
    bin = Bin.new(:pngcrush, '/bin/pngcrush')
    allow(bin).to receive(:version).and_return(SimpleVersion.new('1.7.60'))

    5.times do
      expect do
        bin.check!
      end.to raise_error Bin::BadVersion
    end
  end
end
