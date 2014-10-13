require 'spec_helper'
require 'image_optim/worker'

describe ImageOptim::Worker do
  Worker = ImageOptim::Worker

  describe 'optimize' do
    it 'raises NotImplementedError' do
      image_optim = ImageOptim.new
      worker = Worker.new(image_optim, {})

      expect do
        worker.optimize(double, double)
      end.to raise_error NotImplementedError
    end
  end

end
