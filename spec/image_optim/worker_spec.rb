require 'spec_helper'
require 'image_optim/worker'

describe ImageOptim::Worker do
  before do
    stub_const('Worker', ImageOptim::Worker)
  end

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
