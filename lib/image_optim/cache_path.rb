# frozen_string_literal: true

require 'image_optim/path'

class ImageOptim
  # ImageOptiom::Path with a non self destructing #replace method
  class CachePath < Path
    # Atomic replace dst with self
    def replace(dst)
      dst = self.class.convert(dst)
      tmpdir = [dirname, Path.new(Dir.tmpdir)].find do |dir|
        dir.same_dev?(dst.dirname)
      end
      if tmpdir
        begin
          replace_using_tmp_file(dst, tmpdir)
        rescue Errno::EXDEV
          replace_using_tmp_file(dst, dst.dirname)
        end
      else
        replace_using_tmp_file(dst, dst.dirname)
      end
    end

  private

    def replace_using_tmp_file(dst, tmpdir)
      dst.temp_path_with_tmp_ext(tmpdir) do |temp|
        copy(temp)
        dst.copy_metadata(temp)
        temp.rename(dst.to_s)
      end
    end
  end
end
