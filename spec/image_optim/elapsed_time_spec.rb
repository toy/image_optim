# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/elapsed_time'

describe ImageOptim::ElapsedTime do
  let(:timeout){ 0.01 }

  describe '.now' do
    it 'returns incrementing value' do
      expect{ sleep timeout }.to change{ described_class.now }.by_at_least(timeout)
    end
  end
end
