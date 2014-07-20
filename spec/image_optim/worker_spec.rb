$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/worker'

describe ImageOptim::Worker do
  Worker = ImageOptim::Worker

  describe 'optimize' do
    it 'should raise NotImplementedError unless overriden' do
      class Abc < ImageOptim::Worker; end

      image_optim = ImageOptim.new

      expect do
        Abc.new(image_optim, {}).optimize(double, double)
      end.to raise_error NotImplementedError
    end
  end

end
