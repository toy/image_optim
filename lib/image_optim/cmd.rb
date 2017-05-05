require 'English'
require 'timeout'

class ImageOptim
  # Helper for running commands
  module Cmd
    class << self
      # Run using `system`
      # Return success status
      # Will raise SignalException if process was interrupted
      def run(*args)
        success = system(*args)

        check_status!

        success
      end

      # Run commands using `Process.spawn`
      # Return success status
      # Will raise Timeout::Error when command timeouts
      def run_with_timeout(timeout, *args)
        success = false

        if timeout > 0
          pid = spawn_process(*args)

          begin
            Timeout.timeout(timeout) do
              Process.wait(pid, 0)
              check_status!
              success = $CHILD_STATUS.exitstatus.zero?
            end
          rescue Timeout::Error => e
            cleanup_process(pid)
            raise e
          end
        else
          success = run(*args)
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

      def cleanup_process(pid)
        Thread.new do
          Process.kill('-TERM', pid)
          Process.detach(pid)

          begin
            Timeout.timeout(10) do
              begin
                Process.getpgid(pid)
              rescue Errno::ESRCH
                sleep 0.001
                retry
              end
            end
          rescue Timeout::Error
            Process.kill('-KILL', pid)
          end
        end
      end

      def spawn_process(*args)
        pgroup_opt = Gem.win_platform? ? :new_pgroup : :pgroup

        if RUBY_VERSION >= '1.9'
          if args.last.is_a?(Hash)
            args.last[pgroup_opt] = true
          else
            args.push(pgroup_opt => true)
          end
        end

        if Process.respond_to?(:spawn)
          Process.spawn(*args)
        else
          Process.fork{ exec(*args) }
        end
      end
    end
  end
end
