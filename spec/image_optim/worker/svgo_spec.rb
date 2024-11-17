# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/worker/svgo'

describe ImageOptim::Worker::Svgo do
  describe 'precision option' do
    describe 'default' do
      subject{ described_class::PRECISION_OPTION.default }

      it{ is_expected.to eq(3) }
    end

    describe 'value' do
      let(:subject){ described_class.new(ImageOptim.new, options).precision }

      context 'when lossy not allowed' do
        context 'by default' do
          let(:options){ {} }

          it{ is_expected.to eq(3) }
        end

        context 'when value is passed through options' do
          let(:options){ {precision: 5} }

          it 'warns and keeps default' do
            expect_any_instance_of(described_class).
              to receive(:warn).with(%r{ignored in default/lossless mode})
            is_expected.to eq(3)
          end
        end
      end

      context 'when lossy allowed' do
        context 'by default' do
          let(:options){ {allow_lossy: true} }

          it{ is_expected.to eq(3) }
        end

        context 'when value is passed through options' do
          let(:options){ {allow_lossy: true, precision: 5} }

          it 'sets the value without warning' do
            expect_any_instance_of(described_class).not_to receive(:warn)
            is_expected.to eq(5)
          end
        end
      end
    end
  end
end
