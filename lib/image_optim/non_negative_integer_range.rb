class ImageOptim
  # Denote range of non negative integers for worker option
  class NonNegativeIntegerRange
    # Add handling of range of non negative integers in OptionParser instance
    def self.add_to_option_parser(option_parser)
      option_parser.accept(self, /(\d+)(?:-|\.\.)(\d+)/) do |_, m, n|
        m.to_i..n.to_i
      end
    end
  end
end
