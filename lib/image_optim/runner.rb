# frozen_string_literal: true

require 'image_optim'
require 'image_optim/hash_helpers'
require 'image_optim/runner/glob_helpers'
require 'image_optim/space'
require 'progress'
require 'find'
require 'yaml'

class ImageOptim
  # Handling optimization using image_optim binary
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
          percent = 100 - (size_b * 100.0 / size_a)
          space = Space.space(size_a - size_b)
          format('%5.2f%% %s', percent, space)
        end
      end
    end

    # files, elapsed, kb saved, kb/s
    class BenchmarkResults
      def initialize
        @all = []
      end

      def add(rows)
        @all.concat(rows)
      end

      def print
        if @all.empty?
          puts 'nothing to report'
          return
        end

        report = @all.group_by(&:worker).map do |name, results|
          kb = (results.sum(&:bytes) / 1024.0)
          elapsed = results.sum(&:elapsed)
          {
            'name' => name,
            'files' => results.length,
            'elapsed' => elapsed,
            'kb saved' => kb,
            'kb/s' => (kb / elapsed),
          }
        end

        report = report.sort_by do |row|
          [-row['kb/s'], row['name']]
        end

        puts "\nBENCHMARK RESULTS\n\n"
        Table.new(report).write($stdout)
      end
    end

    def initialize(options)
      options = HashHelpers.deep_symbolise_keys(options)
      @recursive = options.delete(:recursive)
      @progress = options.delete(:show_progress) != false
      @exclude_dir_globs, @exclude_file_globs = %w[dir file].map do |type|
        glob = options.delete(:"exclude_#{type}_glob") || '.*'
        GlobHelpers.expand_braces(glob)
      end

      # --benchmark
      @benchmark = options.delete(:benchmark)
      if @benchmark
        unless options[:threads].nil?
          warning '--benchmark ignores --threads'
          options[:threads] = 1 # for consistency
        end
        if options[:timeout]
          warning '--benchmark ignores --timeout'
        end
      end

      @image_optim = ImageOptim.new(options)
    end

    def run!(args) # rubocop:disable Naming/PredicateMethod
      to_optimize = find_to_optimize(args)
      unless to_optimize.empty?
        if @benchmark
          benchmark_results = BenchmarkResults.new
          benchmark_images(to_optimize).each do |_original, rows| # rubocop:disable Style/HashEachMethods
            benchmark_results.add(rows)
          end
          benchmark_results.print
        else
          results = Results.new

          optimize_images!(to_optimize).each do |original, optimized|
            results.add(original, optimized)
          end

          results.print
        end
      end

      !@warnings
    end

  private

    def benchmark_images(to_optimize, &block)
      to_optimize = to_optimize.with_progress('benchmarking') if @progress
      @image_optim.benchmark_images(to_optimize, &block)
    end

    def optimize_images!(to_optimize, &block)
      to_optimize = to_optimize.with_progress('optimizing') if @progress
      @image_optim.optimize_images!(to_optimize, &block)
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
        elsif File.directory?(path)
          if @recursive
            to_optimize += find_to_optimize_recursive(path)
          else
            warning "#{path} is a directory, use --recursive option"
          end
        else
          warning "#{path} is not a file or a directory or does not exist"
        end
      end
      to_optimize
    end

    def find_to_optimize_recursive(dir)
      to_optimize = []
      Find.find(dir) do |path|
        if File.file?(path)
          next if exclude_file?(dir, path)
          next unless @image_optim.optimizable?(path)

          to_optimize << path
        elsif File.directory?(path)
          Find.prune if dir != path && exclude_dir?(dir, path)
        end
      end
      to_optimize
    end

    def exclude_dir?(dir, path)
      exclude?(dir, path, @exclude_dir_globs)
    end

    def exclude_file?(dir, path)
      exclude?(dir, path, @exclude_file_globs)
    end

    # Check if any of globs matches either part of path relative from dir or
    # just basename
    def exclude?(dir, path, globs)
      relative_path = Pathname(path).relative_path_from(Pathname(dir)).to_s
      basename = File.basename(path)
      globs.any? do |glob|
        File.fnmatch(glob, relative_path, File::FNM_PATHNAME) ||
          File.fnmatch(glob, basename, File::FNM_PATHNAME)
      end
    end

    def warning(message)
      @warnings = true
      warn message
    end
  end
end
