require 'spec_helper'
require 'image_optim/worker/pngquant'

describe ImageOptim::Worker::Pngquant do
  describe 'quality option' do
    describe 'default' do
      subject{ described_class::QUALITY_OPTION.default }

      it{ is_expected.to match(/100\.\.100.*0\.\.100/) }
    end

    describe 'value' do
      let(:options){ {} }
      subject{ described_class.new(ImageOptim.new, options).quality }

      context 'by default' do
        it{ is_expected.to eq(100..100) }
      end

      context 'when lossy allowed by default' do
        let(:options){ {:allow_lossy => true} }

        it{ is_expected.to eq(0..100) }
      end
    end
  end
end
