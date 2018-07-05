# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/timer'

describe ImageOptim::Timer do
  let!(:timer){ described_class.new(1) }

  describe '#elapsed' do
    it 'returns elapsed time' do
      sleep 0.01

      expect(timer.elapsed).to be >= 0.01
    end
  end

  describe '#left' do
    it 'returns time left' do
      sleep 0.01

      expect(timer.left).to be <= 0.99
    end
  end

  describe '#to_f' do
    it 'returns time left' do
      sleep 0.01

      expect(timer.to_f).to be <= 0.99
    end
  end
end
