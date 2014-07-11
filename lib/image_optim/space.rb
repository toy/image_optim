class ImageOptim
  # Present size in readable form as fixed length string
  module Space
    SIZE_SYMBOLS = %w[B K M G T P E].freeze
    BASE = 1024.0
    PRECISION = 1
    LENGTH = 4 + PRECISION + 1

    EMPTY_SPACE = ' ' * LENGTH

    def self.space(size)
      case size
      when 0, nil
        EMPTY_SPACE
      else
        log_denominator = Math.log(size) / Math.log(BASE)
        degree = [log_denominator.floor, SIZE_SYMBOLS.length - 1].min
        denominator = BASE**degree
        number = size / denominator
        "#{degree == 0 ? number.to_i : format("%.#{PRECISION}f", number)}#{SIZE_SYMBOLS[degree]}".rjust(LENGTH)
      end
    end
  end
end
