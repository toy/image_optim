require 'image_optim/bin_resolver/error'
require 'image_optim/bin_resolver/simple_version'
require 'image_optim/bin_resolver/comparable_condition'

class ImageOptim
  class BinResolver
    # Holds bin name and path, gets version
    class Bin
      class BadVersion < Error; end

      attr_reader :name, :path, :version
      def initialize(name, path)
        @name = name.to_sym
        @path = path
        @version = detect_version
      end

      def to_s
        "#{name} #{version || '?'} at #{path}"
      end

      # Fail or warn if version is known to misbehave depending on severity
      def check!
        fail BadVersion, "didn't get version of `#{self}`" unless version

        is = ComparableCondition.is
        case name
        when :pngcrush
          case version
          when c = is.between?('1.7.60', '1.7.65')
            fail BadVersion, "`#{self}` (#{c}) is known to produce broken pngs"
          end
        when :advpng
          case version
          when c = is < '1.17'
            warn "WARN: `#{self}` (#{c}) does not use zopfli"
          end
        when :pngquant
          case version
          when c = is < '2.0'
            fail BadVersion, "`#{self}` (#{c}) is not supported"
          when c = is < '2.1'
            warn "WARN: `#{self}` (#{c}) may be lossy even with quality `100-`"
          end
        end
      end

    private

      # Wrap version_string with SimpleVersion
      def detect_version
        str = version_string
        str && SimpleVersion.new(str)
      end

      # Getting version of bin, will fail for an unknown name
      def version_string
        case name
        when :advpng, :gifsicle, :jpegoptim, :optipng, :pngquant
          `#{path.shellescape} --version 2> /dev/null`[/\d+(\.\d+){1,}/]
        when :svgo
          `#{path.shellescape} --version 2>&1`[/\d+(\.\d+){1,}/]
        when :jhead
          `#{path.shellescape} -V 2> /dev/null`[/\d+(\.\d+){1,}/]
        when :jpegtran
          `#{path.shellescape} -v - 2>&1`[/version (\d+\S*)/, 1]
        when :pngcrush
          `#{path.shellescape} -version 2>&1`[/\d+(\.\d+){1,}/]
        when :pngout
          date_regexp = /[A-Z][a-z]{2} (?: |\d)\d \d{4}/
          date_str = `#{path.shellescape} 2>&1`[date_regexp]
          Date.parse(date_str).strftime('%Y%m%d') if date_str
        when :jpegrescan
          # jpegrescan has no version so just check presence
          path && '-'
        else
          fail "getting `#{name}` version is not defined"
        end
      end
    end
  end
end
