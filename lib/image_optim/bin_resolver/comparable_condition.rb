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
        @method, @args = method.to_sym, args

        case @method
        when :between?
          @args.length == 2 || argument_error!("`between?' expects 2 arguments")
        when :<, :<=, :==, :>, :>=
          @args.length == 1 || argument_error!("`#{method}' expects 1 argument")
        else
          argument_error! "Unknown method `#{method}'"
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

    private

      def argument_error!(message)
        fail ArgumentError, message
      end
    end
  end
end
