require 'spec_helper'
require 'image_optim/path'
require 'tempfile'

describe ImageOptim::Path do
  include CapabilityCheckHelpers

  before do
    stub_const('Path', ImageOptim::Path)
  end

  describe '.convert' do
    it 'returns Path for string' do
      path = 'a'

      expect(Path.convert(path)).to be_a(Path)
      expect(Path.convert(path)).to eq(Path.new(path))

      expect(Path.convert(path)).not_to eq(path)
      expect(Path.convert(path)).not_to be(path)
    end

    it 'returns Path for Pathname' do
      pathname = Pathname.new('a')

      expect(Path.convert(pathname)).to be_a(Path)
      expect(Path.convert(pathname)).to eq(Path.new(pathname))

      expect(Path.convert(pathname)).to eq(pathname)
      expect(Path.convert(pathname)).not_to be(pathname)
    end

    it 'returns same instance for Path' do
      image_path = Path.new('a')

      expect(Path.convert(image_path)).to be_a(Path)
      expect(Path.convert(image_path)).to eq(Path.new(image_path))

      expect(Path.convert(image_path)).to eq(image_path)
      expect(Path.convert(image_path)).to be(image_path)
    end
  end

  describe '#binread' do
    it 'reads binary data' do
      data = (0..255).to_a.pack('c*')

      path = Path.temp_file_path
      path.binwrite(data)

      expect(path.binread).to eq(data)
      if ''.respond_to?(:encoding)
        expect(path.binread.encoding).to eq(Encoding.find('ASCII-8BIT'))
      end
    end
  end

  describe '#replace' do
    let(:src){ Path.temp_file_path }
    let(:dst){ Path.temp_file_path }

    it 'moves data to destination' do
      src.write('src')

      src.replace(dst)

      expect(dst.read).to eq('src')
    end

    it 'removes original file' do
      src.replace(dst)

      expect(src).to_not exist
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
