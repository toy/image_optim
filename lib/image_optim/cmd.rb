require 'English'

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
        Process.respond_to?(:spawn)
      end

      # Run the specified command, and kill it off if it runs longer
      # than `timeout` seconds.
      #
      # Return success status
      # Will raise an error when command timeouts
      def run_with_timeout(timeout, *args)
        return run(*args) unless timeout > 0 && supports_timeout?

        if args.last.is_a?(Hash)
          args.last[Gem.win_platform? ? :new_pgroup : :pgroup] = true
        end

        pid = Process.spawn(*args)
        thread = Process.detach(pid)

        if thread.join(timeout).nil?
          cleanup_process(pid)
          fail TimeoutExceeded
        end

        check_status!
        thread.value.success?
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

      def cleanup_process(pid)
        Thread.new do
          begin
            Process.kill('-TERM', pid)
            now = Time.now

            while Time.now - now < 10
              begin
                Process.getpgid(pid)
                sleep 0.1
              rescue Errno::ESRCH
                break
              end
            end

            if Process.getpgid(pid)
              Process.kill('-KILL', pid)
            end
          rescue Errno::ESRCH
            return
          end
        end
      end
    end
  end
end
