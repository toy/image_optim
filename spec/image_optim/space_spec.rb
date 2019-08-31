# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/space'

describe ImageOptim::Space do
  describe '.space' do
    {
      '      ' => 0,
      '    1B' => 1,
      '   10B' => 10,
      '  100B' => 100,
      ' 1000B' => 1_000,
      '  9.8K' => 10_000,
      ' 97.7K' => 100_000,
      '976.6K' => 1_000_000,
      '  9.5M' => 10_000_000,
      ' 95.4M' => 100_000_000,
    }.each do |space, size|
      it "converts #{size} to #{space}" do
        expect(described_class.space(size)).to eq(space)
      end
    end
  end
end
