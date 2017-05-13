require 'spec_helper'
require 'fspath'
require 'image_optim/cache'
require 'image_optim/path'

describe ImageOptim::Cache do
  before do
    stub_const('Cache', ImageOptim::Cache)
    stub_const('CachePath', ImageOptim::CachePath)
  end

  let(:tmp_file){ double('/somewhere/tmp/foo/bar', :rename => 0) }

  let(:cache_dir) do
    dir = '/somewhere/cache'
    allow(FileUtils).to receive(:mkpath).with(Regexp.new(Regexp.escape(dir)))
    allow(FileUtils).to receive(:touch)
    allow(FSPath).to receive(:temp_file_path) do
      tmp_file
    end
    FSPath.new(dir)
  end

  let(:original) do
    original = double('/somewhere/original', :image_format => :ext)
    allow(Digest::SHA1).to receive(:file).with(original) do
      Digest::SHA1.new << 'some content!'
    end
    original
  end

  let(:optimized) do
    double('/somewhere/optimized', :format => :ext, :basename => 'optimized')
  end

  let(:cached) do
    cached = cache_dir / digest
    allow(Digest::SHA1).to receive(:file).with(cached) do
      Digest::SHA1.new << 'some optimized content!'
    end
    CachePath.convert(cached)
  end

  context 'when cache is disabled (default)' do
    let(:image_optim) do
      double(:image_optim, :cache_dir => nil, :cache_worker_digests => false)
    end
    let(:cache){ Cache.new(image_optim, double) }

    describe :fetch do
      it 'always return block' do
        expect(cache.fetch(original){ optimized }).to be optimized
      end
    end

    describe :fetch do
      it 'does not write to disk' do
        expect(FileUtils).not_to receive(:mv)
        expect(FileUtils).not_to receive(:touch)
        expect(cache.fetch(original){ optimized })
      end
    end
  end

  shared_examples 'an enabled cache' do
    context 'when cached file does not exist' do
      describe :fetch do
        it 'writes to cache when file is optimizable' do
          cached_s = cached.to_s
          expect(FileTest).to receive(:file?).with(cached_s).and_return(false)
          expect(FileTest).not_to receive(:size?).with(cached_s)
          expect(FileUtils).to receive(:mv).with(optimized, tmp_file)
          expect(tmp_file).to receive(:rename).with(cached)

          allow(File).to receive(:umask).and_return(0o024)
          expect(tmp_file).to receive(:chmod).with(0o642)

          expect(cache.fetch(original){ optimized }).to eq(cached)
        end

        it 'writes an empty file to cache when file is already optimized' do
          cached_s = cached.to_s
          expect(FileTest).to receive(:file?).with(cached_s).and_return(false)
          expect(FileTest).not_to receive(:size?).with(cached_s)
          expect(FileUtils).not_to receive(:mv)
          expect(FileUtils).to receive(:touch).with(cached)

          expect(cache.fetch(original){ nil }).to eq(nil)
        end
      end
    end

    context 'when cached file exists (options and/or workers match)' do
      describe(:fetch) do
        it 'returns cached file' do
          cached_s = cached.to_s
          allow(FileTest).to receive(:file?).with(cached_s).and_return(true)
          allow(FileTest).to receive(:size?).with(cached_s).and_return(1234)
          expect(FileUtils).not_to receive(:mv)
          expect(File).not_to receive(:rename)

          expect(cache.fetch(original){}).to eq(cached)
        end

        it 'returns nil when file is already optimized' do
          cached_s = cached.to_s
          allow(FileTest).to receive(:file?).with(cached_s).and_return(true)
          allow(FileTest).to receive(:size?).with(cached_s).and_return(nil)
          expect(FileUtils).not_to receive(:mv)
          expect(File).not_to receive(:rename)

          expect(cache.fetch(original){ nil }).to eq(nil)
        end
      end
    end
  end

  context 'when cache is enabled (without worker digests)' do
    let(:image_optim) do
      double(:image_optim,
             :cache_dir => cache_dir, :cache_worker_digests => false)
    end
    let(:cache) do
      cache = Cache.new(image_optim, {})
      allow(cache).
        to receive(:options_by_format).
        with(original.image_format).
        and_return('some options!')
      allow(cache).
        to receive(:bins_by_format).
        with(original.image_format).
        and_return('some bins!')
      cache
    end
    let(:digest){ cache.send(:digest, original, original.image_format) }

    it_behaves_like 'an enabled cache'
  end

  context 'when cache is enabled (with worker digests)' do
    let(:image_optim) do
      double(:image_optim,
             :cache_dir => cache_dir,
             :cache_worker_digests => true)
    end
    let(:cache) do
      cache = Cache.new(image_optim, {})
      allow(cache).
        to receive(:options_by_format).
        with(original.image_format).
        and_return('some options!')
      allow(cache).
        to receive(:bins_by_format).
        with(original.image_format).
        and_return('some bins!')
      cache
    end
    let(:digest){ cache.send(:digest, original, original.image_format) }

    it_behaves_like 'an enabled cache'
  end
end
