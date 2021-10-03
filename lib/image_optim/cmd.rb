# frozen_string_literal: true

require 'image_optim/errors'
require 'English'

class ImageOptim
  # Helper for running commands
  module Cmd
    class << self
      # Run using `system`
      # Return success status
      # Will raise SignalException if process was interrupted
      def run(*args)
        if args.last.is_a?(Hash) && (timeout = args.last.delete(:timeout))
          args.last[Gem.win_platform? ? :new_pgroup : :pgroup] = true

          pid = Process.spawn(*args)

          waiter = Process.detach(pid)
          if waiter.join(timeout.to_f)
            status = waiter.value

            check_status!(status)

            status.success?
          else
            cleanup(pid, waiter)

            fail Errors::TimeoutExceeded
          end
        else
          success = system(*args)

          check_status!

          success
        end
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

      def check_status!(status = $CHILD_STATUS)
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

      def cleanup(pid, waiter)
        if Gem.win_platform?
          kill('KILL', pid)
        else
          kill('-TERM', pid)

          # Allow 10 seconds for the process to exit
          waiter.join(10)

          kill('-KILL', pid)
        end

        waiter.join
      end

      def kill(signal, pid)
        Process.kill(signal, pid)
      rescue Errno::ESRCH, Errno::EPERM
        # expected
      end
    end
  end
end
