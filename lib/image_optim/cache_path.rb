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
      dst.temp_path_with_tmp_ext(tmpdir || dst.dirname) do |temp|
        copy(temp)
        dst.copy_metadata(temp)
        temp.rename(dst.to_s)
      end
    end
  end
end
