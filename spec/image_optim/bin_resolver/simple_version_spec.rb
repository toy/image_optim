require 'spec_helper'
require 'image_optim/bin_resolver/simple_version'

describe ImageOptim::BinResolver::SimpleVersion do
  helpers = Module.new do
    def v(str)
      ImageOptim::BinResolver::SimpleVersion.new(str)
    end
  end
  include helpers
  extend helpers

  describe 'compares version 1.17' do
    subject{ v '1.17' }

    it{ is_expected.to be > '0' }
    it{ is_expected.to be > '0.1' }
    it{ is_expected.to be > '0.9' }
    it{ is_expected.to be > '1.9' }
    it{ is_expected.to be < '1.17.1' }
    it{ is_expected.to be < '1.99' }
    it{ is_expected.to be < '2.1' }
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
        expect(v variation).to eq(1)
      end
    end
  end

  describe 'conversion' do
    it 'converts Integer' do
      expect(v 117).to eq('117')
    end

    it 'converts Float' do
      expect(v 1.17).to eq('1.17')
    end

    it 'converts String' do
      expect(v '1.17').to eq('1.17')
    end

    it 'converts self' do
      expect(v(v 1.17)).to eq('1.17')
    end
  end
end
