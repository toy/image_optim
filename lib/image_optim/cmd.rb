require 'English'
require 'open3'

class ImageOptim
  # Helper for running commands
  module Cmd
    class TimeoutExceeded < StandardError; end

    class << self
      # Run using `system`
      # Return success status
      # Will raise SignalException if process was interrupted
      def run(*args)
        success = system(*args)

        check_status!

        success
      end

      def supports_timeout?
        if defined?(JRUBY_VERSION)
          JRUBY_VERSION >= '9.0.0.0'
        else
          RUBY_VERSION >= '1.9'
        end
      end

      # Run the specified command, and kill it off if it runs longer
      # than `timeout` seconds.
      #
      # Return success status
      # Will raise an error when command timeouts
      def run_with_timeout(timeout, *args)
        return run(*args) unless timeout > 0 && supports_timeout?

        success = false
        init_options!(args)

        begin
          stdin, stdout, thread = Open3.popen2(*args)
          stdin.close
          stdout.close

          pid = thread[:pid]

          if thread.join(timeout).nil?
            cleanup_process(pid)
            thread.kill
            fail TimeoutExceeded
          elsif thread.value.exitstatus
            success = thread.value.exitstatus.zero?
          end
        end

        success
      end

      # Run using backtick
      # Return captured output
      # Will raise SignalException if process was interrupted
      def capture(cmd)
        output = `#{cmd}`

        check_status!

        output
      end

    private

      def check_status!
        status = $CHILD_STATUS

        return unless status.signaled?

        # jruby incorrectly returns true for `signaled?` if process exits with
        # non zero status. For following code
        #
        #     `sh -c 'exit 66'`
        #     p [$?.signaled?, $?.exitstatus, $?.termsig]
        #
        # jruby outputs `[true, 66, 66]` instead of expected `[false, 66, nil]`
        return if defined?(JRUBY_VERSION) && status.exitstatus == status.termsig

        fail SignalException, status.termsig
      end

      def init_options!(args)
        pgroup_opt = Gem.win_platform? ? :new_pgroup : :pgroup

        if args.last.is_a?(Hash)
          args.last[pgroup_opt] = true
        else
          args.push(pgroup_opt => true)
        end
      end

      def cleanup_process(pid)
        Thread.new do
          Process.kill('-TERM', pid)
          Process.detach(pid)
          now = Time.now

          while Time.now - now < 10
            begin
              Process.kill(0, pid)
              sleep 0.001
              next
            rescue Errno::ESRCH
              break
            end
          end

          if Process.getpgid(pid)
            Process.kill('-KILL', pid)
          end
        end
      end
    end
  end
end
