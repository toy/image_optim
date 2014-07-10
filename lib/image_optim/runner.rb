# encoding: UTF-8

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
    def initialize(args, options)
      fail 'specify paths to optimize' if args.empty?
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
        elsif @recursive
          if File.directory?(arg)
            Find.find(arg) do |path|
              files << path if File.file?(path) && @image_optim.optimizable?(path)
            end
          else
            warning "#{arg} is not a file or a directory or does not exist"
          end
        else
          warning "#{arg} is not a file or does not exist"
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
