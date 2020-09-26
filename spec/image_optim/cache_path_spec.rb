# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/cache_path'
require 'tempfile'

describe ImageOptim::CachePath do
  include CapabilityCheckHelpers

  before do
    stub_const('Path', ImageOptim::Path)
    stub_const('CachePath', ImageOptim::CachePath)
  end

  describe '#replace' do
    let(:src_dir){ Path.temp_dir }
    let(:src){ CachePath.temp_file_path(nil, src_dir) }
    let(:dst){ Path.temp_file_path }

    shared_examples 'replaces file' do
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

      it 'is using temporary file with .tmp extension' do
        expect(src).to receive(:copy).with(having_attributes(:extname => '.tmp')).at_least(:once)

        src.replace(dst)
      end
    end

    context 'when src and dst are on same device' do
      before do
        allow_any_instance_of(File::Stat).to receive(:dev).and_return(0)
      end

      include_examples 'replaces file'
    end

    context 'when src and dst are on different devices' do
      before do
        allow_any_instance_of(File::Stat).to receive(:dev, &:__id__)
      end

      include_examples 'replaces file'
    end

    context 'when src and dst are on same device, but rename causes Errno::EXDEV' do
      before do
        allow_any_instance_of(File::Stat).to receive(:dev).and_return(0)
        allow(described_class).to receive(:temp_file_path).and_call_original
        expect(described_class).to receive(:temp_file_path).
          with([dst.basename.to_s, '.tmp'], src.dirname).
          and_wrap_original do |m, *args, &block|
            m.call(*args) do |tmp|
              expect(tmp).to receive(:rename).with(dst.to_s).and_raise(Errno::EXDEV)
              block.call(tmp)
            end
          end
      end

      include_examples 'replaces file'
    end
  end
end
