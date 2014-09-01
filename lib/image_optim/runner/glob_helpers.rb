class ImageOptim
  class Runner
    # Helper methods for glob
    module GlobHelpers
      class << self
        # Match inner curly braces in glob
        # Negative lookbehind is not used as is not supported by ruby before 1.9
        BRACE_REGEXP = /
          \A
          (
            (?:.*[^\\]|)  # anything ending not with slash or nothing
            (?:\\\\)*     # any number of self escaped slashes
          )
          \{              # open brace
          (
            (?:|.*?[^\\]) # nothing or non greedy anything ending not with slash
            (?:\\\\)*     # any number of self escaped slashes
          )
          \}              # close brace
          (
            .*            # what is left
          )
          \z
        /x

        # Expand curly braces in glob as fnmatch in ruby before 2.0 doesn't
        # support them
        def expand_braces(original_glob)
          expanded = []
          unexpanded = [original_glob]
          while (glob = unexpanded.shift)
            if (m = BRACE_REGEXP.match(glob))
              m[2].split(',', -1).each do |variant|
                unexpanded << "#{m[1]}#{variant}#{m[3]}"
              end
            else
              expanded << glob
            end
          end
          expanded.uniq
        end
      end
    end
  end
end
