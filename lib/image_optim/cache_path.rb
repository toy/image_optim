require 'image_optim/path'

class ImageOptim
  # ImageOptiom::Path with a non self destructing #replace method
  class CachePath < Path
    # Atomic replace dst with self
    def replace(dst)
      dst = self.class.new(dst)
      dst.temp_path(dst.dirname) do |temp|
        copy(temp)
        dst.copy_metadata(temp)
        temp.rename(dst.to_s)
      end
    end
  end
end
