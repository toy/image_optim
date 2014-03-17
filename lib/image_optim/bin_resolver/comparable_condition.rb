class ImageOptim
  class BinResolver
    class ComparableCondition
      class Builder
        Comparable.instance_methods.each do |method|
          define_method method do |*args|
            ComparableCondition.new(method, *args)
          end
        end
      end

      def self.is
        Builder.new
      end

      attr_reader :method, :args
      def initialize(method, *args)
        @method = method.to_sym
        @args = args

        case @method
        when :between?
          raise ArgumentError, "`between?' expects 2 arguments" unless args.length == 2
        when :<, :<=, :==, :>, :>=
          raise ArgumentError, "`#{method}' expects 1 argument" unless args.length == 1
        else
          raise ArgumentError, "Unknown method `#{method}'"
        end
      end

      def ===(to_compare)
        to_compare.send(@method, *@args)
      end

      def to_s
        if @method == :between?
          @args.join('..')
        else
          "#{@method} #{@args.first}"
        end
      end
    end
  end
end
