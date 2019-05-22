# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/option_helpers'

describe ImageOptim::OptionHelpers do
  describe '.limit_with_range' do
    {
      2..4 => 'inclusive',
      2...5 => 'exclusive',
    }.each do |range, type|
      context "for an end #{type} range" do
        it 'returns number when it is in range' do
          expect(described_class.limit_with_range(4, range)).to eq(4)
        end

        it 'returns begin when it is less than minimum' do
          expect(described_class.limit_with_range(1, range)).to eq(2)
        end

        it 'returns end when it is more than maximum' do
          expect(described_class.limit_with_range(10, range)).to eq(4)
        end
      end
    end
  end
end
