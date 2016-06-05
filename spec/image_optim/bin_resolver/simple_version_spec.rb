require 'spec_helper'
require 'image_optim/bin_resolver/simple_version'

describe ImageOptim::BinResolver::SimpleVersion do
  def v(str)
    described_class.new(str)
  end

  describe '#initialize' do
    describe 'conversion' do
      it 'converts Integer' do
        expect(v(117)).to eq('117')
      end

      it 'converts Float' do
        expect(v(1.17)).to eq('1.17')
      end

      it 'converts String' do
        expect(v('1.17')).to eq('1.17')
      end

      it 'converts self' do
        expect(v(v(1.17))).to eq('1.17')
      end
    end

    describe 'normalization' do
      %w[
        1
        01
        1.0
        1.00
        1.0.0
        1.0.0.0
      ].each do |variation|
        it "normalizes #{variation}" do
          expect(v(variation)).to eq(1)
        end
      end
    end
  end

  describe '#to_s' do
    it 'returns the original value converted to String' do
      expect(v(117).to_s).to eq('117')
      expect(v(1.17).to_s).to eq('1.17')
      expect(v('0117').to_s).to eq('0117')
    end
  end

  describe '#<=>' do
    describe 'comparing version 1.17' do
      subject{ v '1.17' }

      it{ is_expected.to be > '0' }
      it{ is_expected.to be > '0.1' }
      it{ is_expected.to be > '0.9' }
      it{ is_expected.to be > '1.9' }
      it{ is_expected.to be < '1.17.1' }
      it{ is_expected.to be < '1.99' }
      it{ is_expected.to be < '2.1' }
    end
  end
end
