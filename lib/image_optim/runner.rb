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
            "#{degree == 0 ? number.to_s : "%.#{PRECISION}f" % number}#{SIZE_SYMBOLS[degree]}".rjust(LENGTH)
          end
        end
      end
    end

    class << self

      def run!(args, options)
        options = HashHelpers.deep_symbolise_keys(options)

        if options[:verbose]
          puts YAML.dump('Options' => HashHelpers.deep_stringify_keys(options)).sub(/\A---\n/, '')
        end

        recursive = options.delete(:recursive)

        image_optim = begin
          ImageOptim.new(options)
        rescue ImageOptim::ConfigurationError => e
          abort e.to_s
        end

        if args.empty?
          abort 'specify paths to optimize'
        end

        files = get_optimisable_files(args, image_optim, recursive)

        optimize!(files, image_optim)
      end

    private

      def optimize!(files, image_optim)
        lines, src_sizes, dst_sizes =
        image_optim.optimize_images(files.with_progress('optimizing')) do |src, dst|
          if dst
            src_size, dst_size = src.size, dst.size
            percent = size_percent(src_size, dst_size)
            dst.replace(src)
            ["#{percent}  #{src}", src_size, dst_size]
          else
            ["------ #{Space::EMPTY_SPACE}  #{src}", src.size, src.size]
          end
        end.transpose

        $stdout.puts lines, "Total: #{size_percent(src_sizes.inject(:+), dst_sizes.inject(:+))}\n"
      end

      def size_percent(src_size, dst_size)
        '%5.2f%% %s' % [100 - 100.0 * dst_size / src_size, Space.space(src_size - dst_size)]
      end

      def get_optimisable_files(args, image_optim, recursive)
        files = []
        args.each do |arg|
          if File.file?(arg)
            if image_optim.optimizable?(arg)
              files << arg
            else
              warn "#{arg} is not an image or there is no optimizer for it"
            end
          else
            if recursive && File.directory?(arg)
              Find.find(arg) do |path|
                files << path if File.file?(path) && image_optim.optimizable?(path)
              end
            else
              warn "#{arg} does not exist"
            end
          end
        end
        files
      end

    end

  end
end
