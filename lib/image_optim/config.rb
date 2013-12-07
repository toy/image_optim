require 'image_optim/option_helpers'
require 'image_optim/configuration_error'
require 'image_optim/worker'

class ImageOptim
  class Config
    include OptionHelpers

    def initialize(options)
      @options = options.dup
    end

    def assert_no_unused_options!
      assert_options_empty!(@options)
    end

    def nice
      nice = @options.delete(:nice)

      case nice
      when true, nil
        10
      when false
        0
      else
        nice.to_i
      end
    end

    def threads
      threads = @options.delete(:threads)

      threads = case threads
      when true, nil
        processor_count
      when false
        1
      else
        threads.to_i
      end

      OptionHelpers.limit_with_range(threads, 1..16)
    end

    def verbose
      !!@options.delete(:verbose)
    end

    def for_worker(klass)
      worker_options = @options.delete(klass.bin_sym)

      case worker_options
      when Hash
        worker_options
      when true, nil
        {}
      when false
        false
      else
        raise ConfigurationError, "Got #{worker_options.inspect} for #{klass.name} options"
      end
    end

  private

    # http://stackoverflow.com/questions/891537/ruby-detect-number-of-cpus-installed
    def processor_count
      @processor_count ||= case host_os = RbConfig::CONFIG['host_os']
      when /darwin9/
        `hwprefs cpu_count`
      when /darwin/
        (`which hwprefs` != '') ? `hwprefs thread_count` : `sysctl -n hw.ncpu`
      when /linux/
        `grep -c processor /proc/cpuinfo`
      when /freebsd/
        `sysctl -n hw.ncpu`
      when /mswin|mingw/
        require 'win32ole'
        wmi = WIN32OLE.connect('winmgmts://')
        cpu = wmi.ExecQuery('select NumberOfLogicalProcessors from Win32_Processor')
        cpu.to_enum.first.NumberOfLogicalProcessors
      else
        warn "Unknown architecture (#{host_os}) assuming one processor."
        1
      end.to_i
    end
  end
end
