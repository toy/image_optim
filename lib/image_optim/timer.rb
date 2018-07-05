# frozen_string_literal: true

require 'image_optim/elapsed_time'

class ImageOptim
  # Hold start time and timeout
  class Timer
    include ElapsedTime

    def initialize(seconds)
      @start = now
      @seconds = seconds
    end

    def elapsed
      now - @start
    end

    def left
      @seconds - elapsed
    end

    alias_method :to_f, :left
  end
end
