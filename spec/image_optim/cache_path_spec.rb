require 'spec_helper'
require 'image_optim/cache_path'
require 'tempfile'

describe ImageOptim::CachePath do
  include CapabilityCheckHelpers

  before do
    stub_const('CachePath', ImageOptim::CachePath)
  end

  describe '#replace' do
    let(:src){ CachePath.temp_file_path }
    let(:dst){ CachePath.temp_file_path }

    it 'moves data to destination' do
      src.write('src')

      src.replace(dst)

      expect(dst.read).to eq('src')
    end

    it 'does not remove original file' do
      src.replace(dst)

      expect(src).to exist
    end

    it 'preserves attributes of destination file' do
      skip 'full file modes are not support' unless any_file_modes_allowed?
      mode = 0o666

      dst.chmod(mode)

      src.replace(dst)

      got = dst.stat.mode & 0o777
      expect(got).to eq(mode), format('expected %04o, got %04o', mode, got)
    end

    it 'does not preserve mtime of destination file' do
      time = src.mtime

      dst.utime(time - 1000, time - 1000)

      src.replace(dst)

      expect(dst.mtime).to be >= time
    end

    it 'changes inode of destination' do
      skip 'inodes are not supported' unless inodes_supported?
      expect{ src.replace(dst) }.to change{ dst.stat.ino }
    end
  end
end
