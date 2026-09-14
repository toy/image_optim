# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/worker/svgo'

describe ImageOptim::Worker::Svgo do
  %w[
    disable_plugins
    enable_plugins
  ].map(&:to_sym).each do |option|
    describe "#{option} option" do
      let(:subject){ described_class.new(ImageOptim.new, value).send(option) }

      context 'default' do
        let(:value){ {} }

        it{ is_expected.to eq([]) }
      end

      context 'when passed single valid value' do
        let(:value){ {option => :pluginName} }

        it 'converts it to a string array' do
          is_expected.to eq(%w[pluginName])
        end
      end

      context 'when passed multiple valid values' do
        let(:value){ {option => [:pluginName, :anotherName]} }

        it 'converts them to a string array' do
          is_expected.to eq(%w[pluginName anotherName])
        end
      end

      context 'when given invalid values' do
        let(:value){ {option => %w[1abc pluginName alert() anotherName]} }

        it 'warns and skips them' do
          expect_any_instance_of(described_class).
            to receive(:warn).with('Doesn\'t look like svgo plugin name: 1abc')
          expect_any_instance_of(described_class).
            to receive(:warn).with('Doesn\'t look like svgo plugin name: alert()')
          is_expected.to eq(%w[pluginName anotherName])
        end
      end
    end
  end

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
