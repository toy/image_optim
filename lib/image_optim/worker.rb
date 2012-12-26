# encoding: UTF-8

require 'shellwords'
require 'image_optim'

class ImageOptim
  class Worker
    class << self
      # List of avaliable workers
      def klasses
        @klasses ||= []
      end

      # Remember all classes inheriting from this one
      def inherited(base)
        klasses << base
      end

      # List of formats which worker can optimize
      def image_formats
        format_from_name = name.downcase[/gif|jpeg|png/]
        format_from_name ? [format_from_name.to_sym] : []
      end

      # Undercored class name
      def underscored_name
        @underscored_name ||= name.split('::').last.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
      end
    end

    include OptionHelpers

    # Binary name or path
    attr_reader :bin

    # Nice level
    attr_reader :nice

    # Be verbose
    attr_reader :verbose

    # Configure (raises on extra options), find binary (raises if not found)
    def initialize(options = {})
      get_option!(options, :bin, default_bin)
      get_option!(options, :nice, 10){ |v| v.to_i }
      get_option!(options, :verbose, false)
      parse_options(options)
      raise BinaryNotFoundError, "`#{bin}` not found" unless system("which -s #{bin.to_s.shellescape}")
      assert_options_empty!(options)
    end

    # Ordering in list of workers
    def run_order
      0
    end

    # Name of binary determined from class name
    def default_bin
      self.class.underscored_name
    end

    # Check if operation resulted in optimized file
    def optimized?(src, dst)
      dst.size? && dst.size < src.size
    end

  private

    def execute(command, *arguments)
      command = [command, *arguments].map(&:to_s).shelljoin
      start = Time.now

      Process.wait(fork do
        $stdout.reopen('/dev/null', 'w')
        $stderr.reopen('/dev/null', 'w')
        Process.setpriority(Process::PRIO_PROCESS, 0, nice)
        exec command
      end)

      raise SignalException.new($?.termsig) if $?.signaled?

      print "#{$?.success? ? '✓' : '✗'} #{Time.now - start}s #{command}\n" if verbose

      $?.success?
    end
  end
end
