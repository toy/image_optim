# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/true_false_nil'

describe ImageOptim::TrueFalseNil do
  describe '.convert' do
    it 'keeps true' do
      expect(described_class.convert(true)).to eq(true)
    end

    it 'keeps false' do
      expect(described_class.convert(false)).to eq(false)
    end

    it 'keeps nil' do
      expect(described_class.convert(nil)).to eq(nil)
    end

    it 'converts truthy to true' do
      expect(described_class.convert(1)).to eq(true)
    end
  end
end
