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

    # Binary name or path
    attr_reader :nice

    # Be verbose
    attr_reader :verbose

    # Leave color
    attr_reader :leave_color

    # Configure (raises on extra options), find binary (raises if not found)
    def initialize(options = {})
      get_option!(options, :bin, default_bin)
      get_option!(options, :nice, 10){ |v| v.to_i }
      get_option!(options, :verbose, false)
      get_option!(options, :leave_color, false)
      parse_options(options)
      raise BinaryNotFoundError, "`#{bin}` not found" if `which #{bin.to_s.shellescape}`.empty?
      assert_options_empty!(options)
    end

    # Put first in list of workers
    def run_first?
    end

    # Priority in list of workers
    def run_priority
      run_first? ? 0 : 1
    end

    # Optimize file from src to dst, return boolean representing success status
    def optimize(src, dst)
      command = [bin, *command_args(src, dst)].map(&:to_s).shelljoin
      start = Time.now
      pid = fork do
        $stdout.reopen('/dev/null', 'w')
        $stderr.reopen('/dev/null', 'w')
        Process.setpriority(Process::PRIO_PROCESS, 0, nice)
        exec command
      end
      Process.wait pid
      duration = Time.now - start
      if $?.signaled?
        raise SignalException.new($?.termsig)
      end
      success = $?.success? && dst.size? && dst.size < src.size
      if verbose
        print "#{success ? '✓' : '✗'} #{duration}s #{command}\n"
      end
      success
    end

    # Name of binary determined from class name
    def default_bin
      self.class.underscored_name
    end
  end
end
