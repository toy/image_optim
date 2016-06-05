require 'spec_helper'
require 'image_optim/worker/pngquant'

describe ImageOptim::Worker::Pngquant do
  describe 'quality option' do
    describe 'default' do
      subject{ described_class::QUALITY_OPTION.default }

      it{ is_expected.to match(/100\.\.100.*0\.\.100/) }
    end

    describe 'value' do
      let(:subject){ described_class.new(ImageOptim.new, options).quality }

      context 'when lossy not allowed' do
        context 'by default' do
          let(:options){ {} }

          it{ is_expected.to eq(100..100) }
        end

        context 'when value is passed through options' do
          let(:options){ {:quality => 10..90} }

          it 'warns and keeps default' do
            expect_any_instance_of(described_class).
              to receive(:warn).with(/ignored in lossless mode/)
            is_expected.to eq(100..100)
          end
        end
      end

      context 'when lossy allowed' do
        context 'by default' do
          let(:options){ {:allow_lossy => true} }

          it{ is_expected.to eq(0..100) }
        end

        context 'when value is passed through options' do
          let(:options){ {:allow_lossy => true, :quality => 10..90} }

          it 'sets the value without warning' do
            expect_any_instance_of(described_class).not_to receive(:warn)
            is_expected.to eq(10..90)
          end
        end

        context 'when passed range begin is less than 0' do
          let(:options){ {:allow_lossy => true, :quality => -50..50} }

          it 'sets begin to 0' do
            is_expected.to eq(0..50)
          end
        end

        context 'when passed range end is more than 100' do
          let(:options){ {:allow_lossy => true, :quality => 50..150} }

          it 'sets end to 100' do
            is_expected.to eq(50..100)
          end
        end
      end
    end
  end
end
