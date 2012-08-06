require 'image_optim'

class ImageOptim
  class Jpegoptim < Worker
    # Strip Comment markers from output file (defaults to true)
    attr_reader :strip_comments

    # Strip Exif markers from output file (defaults to true)
    attr_reader :strip_exif

    # Strip IPTC markers from output file (defaults to true)
    attr_reader :strip_iptc

    # Strip ICC profile markers from output file (defaults to true)
    attr_reader :strip_icc

    # Maximum image quality factor (defaults to 100)
    attr_reader :max_quality

    # Run first if max_quality < 100
    def run_first?
      max_quality < 100
    end

  private

    def parse_options(options)
      get_option!(options, :strip_comments, true){ |v| !!v }
      get_option!(options, :strip_exif, true){ |v| !!v }
      get_option!(options, :strip_iptc, true){ |v| !!v }
      get_option!(options, :strip_icc, !leave_color){ |v| !!v }
      get_option!(options, :max_quality, 100){ |v| v.to_i }
    end

    def command_args(src, dst)
      src.copy(dst)
      args = %W[-q -- #{dst}]
      if strip_comments && strip_exif && strip_iptc && strip_icc
        args.unshift '--strip-all'
      else
        args.unshift '--strip-com' if strip_comments
        args.unshift '--strip-exif' if strip_exif
        args.unshift '--strip-iptc' if strip_iptc
        args.unshift '--strip-icc' if strip_icc
      end
      args.unshift "-m#{max_quality}" if max_quality < 100
      args
    end
  end
end
