require 'digest/sha1'
require 'fspath'
require 'image_optim/cache_path'

class ImageOptim
  # Handles image cache
  class Cache
    def initialize(image_optim, workers_by_format)
      return unless image_optim.cache_dir
      @cache_dir = FSPath.new(image_optim.cache_dir)
      @cache_worker_digests = image_optim.cache_worker_digests
      @options_by_format = Hash[workers_by_format.map do |format, workers|
        [format, workers.map(&:inspect).sort.join(', ')]
      end]
      @bins_by_format = Hash[workers_by_format.map do |format, workers|
        [format, workers.map(&:used_bins).flatten!.map! do |sym|
          bin = image_optim.resolve_bin!(sym)
          "#{bin.name}[#{bin.digest}]"
        end.sort!.uniq.join(', ')]
      end]
    end

    def fetch(original)
      return yield unless @cache_dir

      digest = digest(original, original.image_format)
      cached = @cache_dir / digest
      return cached.size? && CachePath.convert(cached) if cached.file?

      optimized = yield

      cached.dirname.mkpath

      if optimized
        tmp = FSPath.temp_file_path(digest, @cache_dir)
        FileUtils.mv(optimized, tmp)
        tmp.chmod(0o666 & ~File.umask)
        tmp.rename(cached)
        cached_path = CachePath.convert(cached)

        # mark cached image as already optimized
        cached = @cache_dir / digest(cached, original.image_format)
        cached.dirname.mkpath
        FileUtils.touch(cached)

        cached_path
      else
        # mark image as already optimized
        FileUtils.touch(cached)
        nil
      end
    end

  private

    def options_by_format(format)
      @options_by_format[format]
    end

    def bins_by_format(format)
      @bins_by_format[format]
    end

    def digest(path, format)
      digest = Digest::SHA1.file(path)
      digest.update options_by_format(format)
      digest.update bins_by_format(format) if @cache_worker_digests
      s = digest.hexdigest
      "#{s[0..1]}/#{s[2..-1]}"
    end
  end
end
