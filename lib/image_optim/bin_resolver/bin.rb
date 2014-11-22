require 'image_optim/bin_resolver/error'
require 'image_optim/bin_resolver/simple_version'
require 'image_optim/bin_resolver/comparable_condition'
require 'image_optim/cmd'
require 'shellwords'

class ImageOptim
  class BinResolver
    # Holds bin name and path, gets version
    class Bin
      class UnknownVersion < Error; end
      class BadVersion < Error; end

      attr_reader :name, :path, :version
      def initialize(name, path)
        @name = name.to_sym
        @path = path.to_s
        @version = detect_version
      end

      def to_s
        "#{name} #{version || '?'} at #{path}"
      end

      is = ComparableCondition.is

      FAIL_CHECKS = [
        [:pngcrush, is.between?('1.7.60', '1.7.65'), 'is known to produce '\
              'broken pngs'],
        [:pngcrush, is == '1.7.80', 'loses one color in indexed images'],
        [:pngquant, is < '2.0', 'is not supported'],
      ]

      WARN_CHECKS = [
        [:advpng, is < '1.17', 'does not use zopfli'],
        [:gifsicle, is < '1.85', 'does not support removing extension blocks'],
        [:pngcrush, is < '1.7.38', 'does not have blacken flag'],
        [:pngquant, is < '2.1', 'may be lossy even with quality `100-`'],
      ]

      # Fail if version will not work properly
      def check_fail!
        fail UnknownVersion, "didn't get version of #{self}" unless version

        FAIL_CHECKS.each do |bin_name, matcher, message|
          next unless bin_name == name
          next unless matcher.match(version)
          fail BadVersion, "#{self} (#{matcher}) #{message}"
        end
      end

      # Run check_fail!, otherwise warn if version is known to misbehave
      def check!
        check_fail!

        WARN_CHECKS.each do |bin_name, matcher, message|
          next unless bin_name == name
          next unless matcher.match(version)
          warn "WARN: #{self} (#{matcher}) #{message}"
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
          capture("#{escaped_path} --version 2> /dev/null")[/\d+(\.\d+){1,}/]
        when :svgo
          capture("#{escaped_path} --version 2>&1")[/\d+(\.\d+){1,}/]
        when :jhead, :'jpeg-recompress'
          capture("#{escaped_path} -V 2> /dev/null")[/\d+(\.\d+){1,}/]
        when :jpegtran
          capture("#{escaped_path} -v - 2>&1")[/version (\d+\S*)/, 1]
        when :pngcrush
          capture("#{escaped_path} -version 2>&1")[/\d+(\.\d+){1,}/]
        when :pngout
          date_regexp = /[A-Z][a-z]{2} (?: |\d)\d \d{4}/
          date_str = capture("#{escaped_path} 2>&1")[date_regexp]
          Date.parse(date_str).strftime('%Y%m%d') if date_str
        when :jpegrescan
          # jpegrescan has no version so just check presence
          path && '-'
        else
          fail "getting `#{name}` version is not defined"
        end
      end

      def capture(cmd)
        Cmd.capture(cmd)
      end

      def escaped_path
        path.shellescape
      end
    end
  end
end
