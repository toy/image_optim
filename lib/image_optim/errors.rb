# frozen_string_literal: true

class ImageOptim
  class Error < StandardError; end

  module Errors
    class TimeoutExceeded < Error; end
  end
end
