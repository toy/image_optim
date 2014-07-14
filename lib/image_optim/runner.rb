require 'image_optim'
require 'image_optim/hash_helpers'
require 'image_optim/true_false_nil'
require 'image_optim/space'
require 'progress'
require 'optparse'
require 'find'
require 'yaml'

class ImageOptim
  class Runner
    # Collect and output results of optimization
    class Results
      def initialize
        @lines = []
        @original_size_sum = 0
        @optimized_size_sum = 0
      end

      def add(original, optimized)
        original_size = optimized ? optimized.original_size : original.size
        optimized_size = optimized ? optimized.size : original.size
        @lines << "#{size_percent(original_size, optimized_size)}  #{original}"
        @original_size_sum += original_size
        @optimized_size_sum += optimized_size
      end

      def print
        puts @lines
        puts "Total: #{size_percent(@original_size_sum, @optimized_size_sum)}"
      end

    private

      def size_percent(size_a, size_b)
        if size_a == size_b
          "------ #{Space::EMPTY_SPACE}"
        else
          percent = 100 - 100.0 * size_b / size_a
          space = Space.space(size_a - size_b)
          format('%5.2f%% %s', percent, space)
        end
      end
    end

    def initialize(args, options)
      fail 'specify paths to optimize' if args.empty?
      options = HashHelpers.deep_symbolise_keys(options)
      @recursive = options.delete(:recursive)
      @image_optim = ImageOptim.new(options)
      @to_optimize = find_to_optimize(args)
    end

    def run!
      unless @to_optimize.empty?
        results = Results.new

        optimize_images! do |original, optimized|
          results.add(original, optimized)
        end

        results.print
      end

      !@warnings
    end

    def self.run!(args, options)
      new(args, options).run!
    end

  private

    def optimize_images!(&block)
      @image_optim.
        optimize_images!(@to_optimize.with_progress('optimizing'), &block)
    end

    def find_to_optimize(paths)
      to_optimize = []
      paths.each do |path|
        if File.file?(path)
          if @image_optim.optimizable?(path)
            to_optimize << path
          else
            warning "#{path} is not an image or there is no optimizer for it"
          end
        elsif @recursive
          if File.directory?(path)
            to_optimize += find_to_optimize_recursive(path)
          else
            warning "#{path} is not a file or a directory or does not exist"
          end
        else
          warning "#{path} is not a file or does not exist"
        end
      end
      to_optimize
    end

    def find_to_optimize_recursive(dir)
      to_optimize = []
      Find.find(dir) do |path|
        next unless File.file?(path)
        next unless @image_optim.optimizable?(path)
        to_optimize << path
      end
      to_optimize
    end

    def warning(message)
      @warnings = true
      warn message
    end
  end
end
