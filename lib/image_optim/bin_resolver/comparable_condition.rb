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
          unless args.length == 2
            fail ArgumentError, "`between?' expects 2 arguments"
          end
        when :<, :<=, :==, :>, :>=
          unless args.length == 1
            fail ArgumentError, "`#{method}' expects 1 argument"
          end
        else
          fail ArgumentError, "Unknown method `#{method}'"
        end
      end

      def ===(other)
        other.send(@method, *@args)
      end
      alias_method :match, :===

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
