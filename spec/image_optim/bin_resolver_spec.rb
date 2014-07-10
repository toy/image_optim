$:.unshift File.expand_path('../../../lib', __FILE__)
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
      resolver.should_receive(:accessible?).with(:ls).once.and_return(true)
      FSPath.should_not_receive(:temp_dir)

      5.times do
        resolver.resolve!(:ls)
      end
      resolver.env_path.should eq("#{ENV['PATH']}:#{ImageOptim::BinResolver::VENDOR_PATH}")
    end
  end

  it 'should resolve bin specified in ENV' do
    path = (FSPath(__FILE__).dirname / '../bin/image_optim').relative_path_from(Dir.pwd).to_s
    with_env 'IMAGE_OPTIM_BIN', path do
      tmpdir = double(:tmpdir)
      symlink = double(:symlink)

      resolver.should_receive(:accessible?).with(:image_optim).once.and_return(true)
      FSPath.should_receive(:temp_dir).once.and_return(tmpdir)
      tmpdir.should_receive(:/).with(:image_optim).once.and_return(symlink)
      symlink.should_receive(:make_symlink).with(File.expand_path(path)).once

      at_exit_blocks = []
      resolver.should_receive(:at_exit).once do |&block|
        at_exit_blocks.unshift(block)
      end

      5.times do
        resolver.resolve!(:image_optim)
      end
      resolver.env_path.should eq("#{tmpdir.to_str}:#{ENV['PATH']}:#{ImageOptim::BinResolver::VENDOR_PATH}")

      FileUtils.should_receive(:remove_entry_secure).with(tmpdir)
      at_exit_blocks.each(&:call)
    end
  end

  it 'should raise on failure to resolve bin' do
    with_env 'SHOULD_NOT_EXIST_BIN', nil do
      resolver.should_receive(:accessible?).with(:should_not_exist).once.and_return(false)
      FSPath.should_not_receive(:temp_dir)

      5.times do
        expect do
          resolver.resolve!(:should_not_exist)
        end.to raise_error ImageOptim::BinNotFoundError
      end
      resolver.env_path.should eq("#{ENV['PATH']}:#{ImageOptim::BinResolver::VENDOR_PATH}")
    end
  end

  it 'should raise on failure to resolve bin specified in ENV' do
    path = (FSPath(__FILE__).dirname / '../bin/should_not_exist_bin').relative_path_from(Dir.pwd).to_s
    with_env 'SHOULD_NOT_EXIST_BIN', path do
      tmpdir = double(:tmpdir)
      symlink = double(:symlink)

      resolver.should_receive(:accessible?).with(:should_not_exist).once.and_return(false)
      FSPath.should_receive(:temp_dir).once.and_return(tmpdir)
      tmpdir.should_receive(:/).with(:should_not_exist).once.and_return(symlink)
      symlink.should_receive(:make_symlink).with(File.expand_path(path)).once

      at_exit_blocks = []
      resolver.should_receive(:at_exit).once do |&block|
        at_exit_blocks.unshift(block)
      end

      5.times do
        expect do
          resolver.resolve!(:should_not_exist)
        end.to raise_error ImageOptim::BinNotFoundError
      end
      resolver.env_path.should eq("#{tmpdir.to_str}:#{ENV['PATH']}:#{ImageOptim::BinResolver::VENDOR_PATH}")

      FileUtils.should_receive(:remove_entry_secure).with(tmpdir)
      at_exit_blocks.each(&:call)
    end
  end

  it 'should resolve bin only once' do
    with_env 'LS_BIN', nil do
      resolver.should_receive(:resolve?).once.with(:ls){ sleep 0.1; true }

      10.times.map do
        Thread.new do
          resolver.resolve!(:ls)
        end
      end.each(&:join)
    end
  end

  it 'should raise on detection of problematic version' do
    with_env 'PNGCRUSH_BIN', nil do
      resolver.should_receive(:accessible?).with(:pngcrush).once.and_return(true)
      resolver.should_receive(:version).with(:pngcrush).once.and_return('1.7.60')
      FSPath.should_not_receive(:temp_dir)

      5.times do
        expect do
          resolver.resolve!(:pngcrush)
        end.to raise_error ImageOptim::BadBinVersion
      end
      resolver.env_path.should eq("#{ENV['PATH']}:#{ImageOptim::BinResolver::VENDOR_PATH}")
    end
  end
end
