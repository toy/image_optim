class ImageOptim
  class BinResolver
    # Allows to externalize conditions for an instance of Comparable to use in
    # case statemens
    #
    #     is = ComparableCondition.is
    #     case rand(100)
    #     when is < 10 then # ...
    #     when is.between?(13, 23) then # ...
    #     when is >= 90 then # ...
    #     end
    class ComparableCondition
      # Helper class for creating conditions using ComparableCondition.is
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
