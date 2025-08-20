# frozen_string_literal: true

class ImageOptim
  # Benchmark result for one worker+src
  class Benchmark
    attr_reader :bytes, :elapsed, :worker

    def initialize(src:, dst:, elapsed:, worker:)
      @bytes = bytes_saved(src, dst)
      @elapsed = elapsed
      @worker = worker.class.bin_sym.to_s
    end

    def bytes_saved(src, dst)
      src, dst = src.size, dst.size
      return 0 if dst == 0 # failure
      return 0 if dst > src # the file got bigger
      src - dst
    end
  end
end
