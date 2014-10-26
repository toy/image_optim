# encoding: UTF-8

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

        parser = new
        options = {}
        DEFINE.call(parser, options)
        parser.parse!(args)
        options
      rescue OptionParser::ParseError => e
        abort "#{e}\n\n#{parser.help}"
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
    |Usege:
    |  #{op.program_name} [options] image_path …
    |
    |Configuration will be read and prepanded to options from two paths:
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

  op.on('--[no-]threads N', Integer, 'Number of threads or disable '\
      '(defaults to number of processors)') do |threads|
    options[:threads] = threads
  end

  op.on('--[no-]nice N', Integer, 'Nice level (defaults to 10)') do |nice|
    options[:nice] = nice
  end

  op.separator nil
  op.separator '  Disabling workers:'

  ImageOptim::Worker.klasses.each do |klass|
    bin = klass.bin_sym
    op.on("--no-#{bin}", "disable #{bin} worker") do |enable|
      options[bin] = enable
    end
  end

  op.separator nil
  op.separator '  Worker options:'

  ImageOptim::Worker.klasses.each_with_index do |klass, i|
    op.separator nil unless i.zero?

    bin = klass.bin_sym
    klass.option_definitions.each do |option_definition|
      name = option_definition.name.to_s.gsub('_', '-')
      default = option_definition.default
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

      description_lines = %W[
        #{option_definition.description.gsub(' - ', ' - ')}
        (defaults to #{default})
      ].join(' ').
        scan(/.*?.{1,60}(?:\s|\z)/).
        join("\n  ").
        split("\n")

      op.on("--#{bin}-#{name} #{marking}", type, *description_lines) do |value|
        options[bin] = {} unless options[bin].is_a?(Hash)
        options[bin][option_definition.name.to_sym] = value
      end
    end
  end

  op.separator nil
  op.separator '  Common options:'

  op.on_tail('-v', '--verbose', 'Verbose output') do
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
