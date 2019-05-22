# encoding: UTF-8
# frozen_string_literal: true

require 'image_optim'
require 'image_optim/true_false_nil'
require 'image_optim/non_negative_integer_range'
require 'optparse'

class ImageOptim
  class Runner
    # Parse options from arguments to image_optim binary
    class OptionParser < ::OptionParser
      # Parse and remove options from args, return options Hash
      # Calls abort in case of parse error
      def self.parse!(args)
        # assume -v to be a request to print version if it is the only argument
        args = %w[--version] if args == %w[-v]

        options = {}
        parser = new(options)
        parser.parse!(args)
        options
      rescue OptionParser::ParseError => e
        abort "#{e}\n\n#{parser.help}"
      end

      # After initialization passes self and options to DEFINE
      def initialize(options)
        super
        DEFINE.call(self, options)
      end

      # Wraps and indents lines of overriden method
      def help
        text = super

        # reserve one column
        columns = terminal_columns - 1
        # 1 for distance between summary and description
        # 2 for additional indent
        wrapped_indent = summary_indent + ' ' * (summary_width + 1 + 2)
        wrapped_width = columns - wrapped_indent.length
        # don't try to wrap if there is too little space for description
        return text if wrapped_width < 20

        wrapped = ''.dup
        text.split("\n").each do |line|
          if line.length <= columns
            wrapped << line << "\n"
          else
            indented = line =~ /^\s/
            wrapped << line.slice!(wrap_regex(columns)) << "\n"
            line.scan(wrap_regex(wrapped_width)) do |part|
              wrapped << wrapped_indent if indented
              wrapped << part << "\n"
            end
          end
        end
        wrapped
      end

    private

      def terminal_columns
        stty_columns = `stty size 2> /dev/null`[/^\d+ (\d+)$/, 1]
        stty_columns ? stty_columns.to_i : `tput cols`.to_i
      end

      def wrap_regex(width)
        /.*?.{1,#{width}}(?:\s|\z)/
      end
    end
  end
end

ImageOptim::Runner::OptionParser::DEFINE = proc do |op, options|
  unless op.is_a?(OptionParser)
    fail ArgumentError, "expected instance of OptionParser, got #{op.inspect}"
  end
  unless options.is_a?(Hash)
    fail ArgumentError, "expected instance of Hash, got #{options.inspect}"
  end

  ImageOptim::TrueFalseNil.add_to_option_parser(op)
  ImageOptim::NonNegativeIntegerRange.add_to_option_parser(op)

  op.banner = <<-TEXT.gsub(/^\s*\|/, '')
    |#{ImageOptim.full_version}
    |
    |Usage:
    |  #{op.program_name} [options] image_path …
    |
    |Configuration will be read and prepended to options from two paths:
    |  #{ImageOptim::Config::GLOBAL_PATH}
    |  #{ImageOptim::Config::LOCAL_PATH}
    |
  TEXT

  op.on('--config-paths PATH1,PATH2', Array, 'Config paths to use instead of '\
      'default ones') do |paths|
    options[:config_paths] = paths
  end

  op.separator nil

  op.on('-r', '-R', '--recursive', 'Recursively scan directories '\
      'for images') do |recursive|
    options[:recursive] = recursive
  end

  op.on("--exclude-dir 'GLOB'", 'Glob for excluding directories '\
      '(defaults to .*)') do |glob|
    options[:exclude_dir_glob] = glob
  end

  op.on("--exclude-file 'GLOB'", 'Glob for excluding files '\
      '(defaults to .*)') do |glob|
    options[:exclude_file_glob] = glob
  end

  op.on("--exclude 'GLOB'", 'Set glob for excluding both directories and '\
      'files') do |glob|
    options[:exclude_file_glob] = options[:exclude_dir_glob] = glob
  end

  op.separator nil

  op.on('--no-progress', 'Disable showing progress') do |show_progress|
    options[:show_progress] = show_progress
  end

  op.on('--[no-]threads N', Integer, 'Number of threads or disable '\
      '(defaults to number of processors)') do |threads|
    options[:threads] = threads
  end

  op.on('--[no-]nice N', Integer, 'Nice level, priority of all used tools '\
      'with higher value meaning lower priority, in range -20..19, negative '\
      'values can be set only if run by root user (defaults to 10)') do |nice|
    options[:nice] = nice
  end

  op.on('--[no-]pack', 'Require image_optim_pack or disable it, '\
      'by default image_optim_pack will be used if available, '\
      'will turn on skip-missing-workers unless explicitly disabled') do |pack|
    options[:pack] = pack
  end

  op.separator nil
  op.separator '  Caching:'

  op.on('--cache-dir DIR', 'Cache optimized images '\
        'into the specified directory') do |cache_dir|
    options[:cache_dir] = cache_dir
  end

  op.on('--cache-worker-digests', 'Cache worker digests '\
        '(updating workers invalidates cache)') do |cache_worker_digests|
    options[:cache_worker_digests] = cache_worker_digests
  end

  op.separator nil
  op.separator '  Disabling workers:'

  op.on('--[no-]skip-missing-workers', 'Skip workers with missing or '\
      'problematic binaries') do |skip|
    options[:skip_missing_workers] = skip
  end

  ImageOptim::Worker.klasses.each do |klass|
    bin = klass.bin_sym
    op.on("--no-#{bin}", "disable #{bin} worker") do |enable|
      options[bin] = enable
    end
  end

  op.separator nil
  op.separator '  Worker options:'

  op.on('--allow-lossy', 'Allow lossy workers and '\
      'optimizations') do |allow_lossy|
    options[:allow_lossy] = allow_lossy
  end

  op.separator nil

  ImageOptim::Worker.klasses.each_with_index do |klass, i|
    next if klass.option_definitions.empty?

    op.separator nil unless i == 0

    bin = klass.bin_sym
    klass.option_definitions.each do |option_definition|
      name = option_definition.name.to_s.tr('_', '-')
      default = option_definition.default_description
      type = option_definition.type

      type, marking = case
      when [TrueClass, FalseClass, ImageOptim::TrueFalseNil].include?(type)
        [type, 'B']
      when Integer >= type
        [Integer, 'N']
      when Array >= type
        [Array, 'a,b,c']
      when ImageOptim::NonNegativeIntegerRange == type
        [type, 'M-N']
      else
        fail "Unknown type #{type}"
      end

      description = option_definition.description.gsub(' - ', ' - ')
      unless description['(defaults']
        description << " (defaults to #{default})"
      end

      op.on("--#{bin}-#{name} #{marking}", type, description) do |value|
        options[bin] = {} unless options[bin].is_a?(Hash)
        options[bin][option_definition.name.to_sym] = value
      end
    end
  end

  op.separator nil
  op.separator '  Common options:'

  op.on_tail('-v', '--verbose', 'Verbose output (show global and worker '\
      'config, binary resolution log, information about each tool invocation, '\
      'backtrace of exception)') do
    options[:verbose] = true
  end

  op.on_tail('-h', '--help', 'Show help and exit') do
    puts op.help
    exit
  end

  op.on_tail('--version', 'Show version and exit') do
    puts ImageOptim.version
    exit
  end

  op.on_tail('--info', 'Show environment info and exit') do
    options[:verbose] = true
    options[:only_info] = true
  end
end
