# frozen_string_literal: true

require 'English'

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
    end
  end
end
