class ImageOptim
  class BinResolver
    # Allows comparision of simple versions, only numbers separated by dots are
    # taken into account
    class SimpleVersion
      include Comparable

      # Numbers extracted from version string
      attr_reader :parts

      # Initialize with a string or an object convertible to string
      #
      #    SimpleVersion.new('2.0.1') <=> SimpleVersion.new(2)
      def initialize(str)
        @str = String(str)
        @parts = @str.split('.').map(&:to_i).reverse.drop_while(&:zero?).reverse
      end

      # Returns original version string
      def to_s
        @str
      end

      # Compare version parts of self with other
      def <=>(other)
        other = self.class.new(other) unless other.is_a?(self.class)
        parts <=> other.parts
      end
    end
  end
end
