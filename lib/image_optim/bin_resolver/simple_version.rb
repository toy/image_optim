class ImageOptim
  class BinResolver
    class SimpleVersion
      include Comparable

      attr_reader :parts
      def initialize(str)
        @str = String(str)
        @parts = @str.split('.').map(&:to_i).reverse.drop_while(&:zero?).reverse
      end

      def to_s
        @str
      end

      def <=>(other)
        other = self.class.new(other) unless other.is_a?(self.class)
        parts <=> other.parts
      end
    end
  end
end
