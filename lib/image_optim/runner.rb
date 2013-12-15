# encoding: UTF-8

require 'image_optim'
require 'image_optim/hash_helpers'
require 'image_optim/true_false_nil'
require 'progress'
require 'optparse'
require 'find'
require 'yaml'

class ImageOptim
  class Runner
    module Space
      SIZE_SYMBOLS = %w[B K M G T P E].freeze
      PRECISION = 1
      LENGTH = 4 + PRECISION + 1

      EMPTY_SPACE = ' ' * LENGTH

      class << self
        attr_writer :base10
        def denominator
          @denominator ||= @base10 ? 1000.0 : 1024.0
        end

        def space(size)
          case size
          when 0, nil
            EMPTY_SPACE
          else
            log_denominator = Math.log(size) / Math.log(denominator)
            degree = [log_denominator.floor, SIZE_SYMBOLS.length - 1].min
            number = size / (denominator ** degree)
            "#{degree == 0 ? number.to_i : "%.#{PRECISION}f" % number}#{SIZE_SYMBOLS[degree]}".rjust(LENGTH)
          end
        end
      end
    end

    def initialize(args, options)
      raise 'specify paths to optimize' if args.empty?
      options = HashHelpers.deep_symbolise_keys(options)
      @recursive = options.delete(:recursive)
      @image_optim = ImageOptim.new(options)
      @files = find_files(args)
    end

    def run!
      unless @files.empty?
        lines, original_sizes, optimized_sizes =
        @image_optim.optimize_images!(@files.with_progress('optimizing')) do |original, optimized|
          original_size = optimized ? optimized.original_size : original.size
          optimized_size = optimized ? optimized.size : original.size
          ["#{size_percent(original_size, optimized_size)}  #{original}", original_size, optimized_size]
        end.transpose

        puts lines, "Total: #{size_percent(original_sizes.inject(:+), optimized_sizes.inject(:+))}"
      end

      !warnings?
    end

    def warnings?
      !!@warnings
    end

    def self.run!(args, options)
      new(args, options).run!
    end

  private

    def find_files(args)
      files = []
      args.each do |arg|
        if File.file?(arg)
          if @image_optim.optimizable?(arg)
            files << arg
          else
            warning "#{arg} is not an image or there is no optimizer for it"
          end
        elsif @recursive && File.directory?(arg)
          Find.find(arg) do |path|
            files << path if File.file?(path) && @image_optim.optimizable?(path)
          end
        else
          warning "#{arg} does not exist"
        end
      end
      files
    end

    def warning(message)
      @warnings = true
      warn message
    end

    def size_percent(size_a, size_b)
      if size_a == size_b
        "------ #{Space::EMPTY_SPACE}"
      else
        '%5.2f%% %s' % [100 - 100.0 * size_b / size_a, Space.space(size_a - size_b)]
      end
    end

  end
end
