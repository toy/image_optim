# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/worker/jpegrecompress'

describe ImageOptim::Worker::Jpegrecompress do
  describe 'method value' do
    let(:subject){ described_class.new(ImageOptim.new, method).method }

    context 'default' do
      let(:method){ {} }

      it{ is_expected.to eq('ssim') }
    end

    context 'uses default when invalid' do
      let(:method){ {:method => 'invalid'} }

      it 'warns and keeps default' do
        expect_any_instance_of(described_class).
          to receive(:warn).with('Unknown method for jpegrecompress: invalid')
        is_expected.to eq('ssim')
      end
    end

    context 'can use a valid option' do
      let(:method){ {:method => 'smallfry'} }

      it{ is_expected.to eq('smallfry') }
    end
  end
end
