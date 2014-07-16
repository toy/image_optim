$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/worker'

describe ImageOptim::Worker do
  Worker = ImageOptim::Worker

  describe 'optimize' do
    it 'should raise NotImplementedError unless overriden' do
      class Abc < ImageOptim::Worker; end

      expect do
        Abc.new({}).optimize(double, double)
      end.to raise_error NotImplementedError
    end
  end

end
