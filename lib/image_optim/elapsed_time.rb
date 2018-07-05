# frozen_string_literal: true

class ImageOptim
  # Use Process.clock_gettime if available to get time more fitting to calculate elapsed time
  module ElapsedTime
    CLOCK_NAME = %w[
      CLOCK_UPTIME_RAW
      CLOCK_UPTIME
      CLOCK_MONOTONIC_RAW
      CLOCK_MONOTONIC
      CLOCK_REALTIME
    ].find{ |name| Process.const_defined?(name) }

    CLOCK_ID = CLOCK_NAME && Process.const_get(CLOCK_NAME)

  module_function

    def now
      if CLOCK_ID
        Process.clock_gettime(CLOCK_ID)
      else
        Time.now.to_f
      end
    end
  end
end
