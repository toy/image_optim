class ImageOptim
  # Denote ternary value (`true`/`false`/`nil`) for worker option
  class TrueFalseNil
    # Add handling of ternary value in OptionParser instance, maps `nil` and
    # `'nil'` to `nil`
    def self.add_to_option_parser(option_parser)
      completing = OptionParser.top.atype[TrueClass][0].merge('nil' => nil)
      option_parser.accept(self, completing){ |_arg, val| val }
    end
  end
end
