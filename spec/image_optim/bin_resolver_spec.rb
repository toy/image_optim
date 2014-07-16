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
  let(:image_optim){ double(:image_optim, :verbose => false) }
  let(:resolver){ ImageOptim::BinResolver.new(image_optim) }

  it 'should resolve bin in path' do
    with_env 'LS_BIN', nil do
      expect(resolver).to receive(:accessible?).with(:ls).once.and_return(true)
      expect(FSPath).not_to receive(:temp_dir)

      5.times do
        resolver.resolve!(:ls)
      end
      expect(resolver.env_path).to eq([
        ENV['PATH'],
        ImageOptim::BinResolver::VENDOR_PATH,
      ].join(':'))
    end
  end

  it 'should resolve bin specified in ENV' do
    path = 'some/path/image_optim2.3.4'
    with_env 'IMAGE_OPTIM_BIN', path do
      tmpdir = double(:tmpdir, :to_str => 'tmpdir')
      symlink = double(:symlink)

      expect(resolver).to receive(:accessible?).
        with(:image_optim).once.and_return(true)
      expect(FSPath).to receive(:temp_dir).
        once.and_return(tmpdir)
      expect(tmpdir).to receive(:/).
        with(:image_optim).once.and_return(symlink)
      expect(symlink).to receive(:make_symlink).
        with(File.expand_path(path)).once

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
        ImageOptim::BinResolver::VENDOR_PATH,
      ].join(':'))

      expect(FileUtils).to receive(:remove_entry_secure).with(tmpdir)
      at_exit_blocks.each(&:call)
    end
  end

  it 'should raise on failure to resolve bin' do
    with_env 'SHOULD_NOT_EXIST_BIN', nil do
      expect(resolver).to receive(:accessible?).
        with(:should_not_exist).once.and_return(false)
      expect(FSPath).not_to receive(:temp_dir)

      5.times do
        expect do
          resolver.resolve!(:should_not_exist)
        end.to raise_error ImageOptim::BinNotFoundError
      end
      expect(resolver.env_path).to eq([
        ENV['PATH'],
        ImageOptim::BinResolver::VENDOR_PATH,
      ].join(':'))
    end
  end

  it 'should raise on failure to resolve bin specified in ENV' do
    path = 'some/path/should_not_exist_bin'
    with_env 'SHOULD_NOT_EXIST_BIN', path do
      tmpdir = double(:tmpdir, :to_str => 'tmpdir')
      symlink = double(:symlink)

      expect(resolver).to receive(:accessible?).
        with(:should_not_exist).once.and_return(false)
      expect(FSPath).to receive(:temp_dir).
        once.and_return(tmpdir)
      expect(tmpdir).to receive(:/).
        with(:should_not_exist).once.and_return(symlink)
      expect(symlink).to receive(:make_symlink).
        with(File.expand_path(path)).once

      at_exit_blocks = []
      expect(resolver).to receive(:at_exit).once do |&block|
        at_exit_blocks.unshift(block)
      end

      5.times do
        expect do
          resolver.resolve!(:should_not_exist)
        end.to raise_error ImageOptim::BinNotFoundError
      end
      expect(resolver.env_path).to eq([
        tmpdir,
        ENV['PATH'],
        ImageOptim::BinResolver::VENDOR_PATH,
      ].join(':'))

      expect(FileUtils).to receive(:remove_entry_secure).with(tmpdir)
      at_exit_blocks.each(&:call)
    end
  end

  it 'should resolve bin only once' do
    with_env 'LS_BIN', nil do
      expect(resolver).to receive(:resolve?).once.with(:ls){ sleep 0.1; true }

      10.times.map do
        Thread.new do
          resolver.resolve!(:ls)
        end
      end.each(&:join)
    end
  end

  it 'should raise on detection of problematic version' do
    with_env 'PNGCRUSH_BIN', nil do
      expect(resolver).to receive(:accessible?).
        with(:pngcrush).once.and_return(true)
      expect(resolver).to receive(:version).
        with(:pngcrush).once.and_return('1.7.60')
      expect(FSPath).not_to receive(:temp_dir)

      5.times do
        expect do
          resolver.resolve!(:pngcrush)
        end.to raise_error ImageOptim::BadBinVersion
      end
      expect(resolver.env_path).to eq([
        ENV['PATH'],
        ImageOptim::BinResolver::VENDOR_PATH,
      ].join(':'))
    end
  end
end
