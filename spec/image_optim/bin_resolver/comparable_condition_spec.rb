require 'spec_helper'
require 'image_optim/bin_resolver/comparable_condition'

describe ImageOptim::BinResolver::ComparableCondition do
  let(:is){ ImageOptim::BinResolver::ComparableCondition.is }

  it 'builds conditions' do
    expect(is.between?(10, 20).method).to eq(:between?)
    expect(is.between?(10, 20).args).to eq([10, 20])

    expect((is >= 15).method).to eq(:>=)
    expect((is >= 15).args).to eq([15])

    expect((is < 30).method).to eq(:<)
    expect((is < 30).args).to eq([30])
  end

  it 'stringifies conditions' do
    expect(is.between?(10, 20).to_s).to eq('10..20')
    expect((is >= 15).to_s).to eq('>= 15')
    expect((is < 30).to_s).to eq('< 30')
  end

  it 'matches conditions' do
    expect(is.between?(10, 20)).not_to match 9
    expect(is.between?(10, 20)).to match 15
    expect(is.between?(10, 20)).not_to match 21

    expect(is >= 15).not_to match 14
    expect(is >= 15).to match 15
    expect(is >= 15).to match 16

    expect(is < 30).to match 29
    expect(is < 30).not_to match 30
    expect(is < 30).not_to match 31
  end
end
