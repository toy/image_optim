$:.unshift File.expand_path('../../../../lib', __FILE__)
require 'rspec'
require 'image_optim/bin_resolver/comparable_condition'

describe ImageOptim::BinResolver::ComparableCondition do
  is = ImageOptim::BinResolver::ComparableCondition.is

  it 'should build conditions' do
    expect(is.between?(10, 20).method).to eq(:between?)
    expect(is.between?(10, 20).args).to eq([10, 20])

    expect((is >= 15).method).to eq(:>=)
    expect((is >= 15).args).to eq([15])

    expect((is < 30).method).to eq(:<)
    expect((is < 30).args).to eq([30])
  end

  it 'should stringify conditions' do
    expect(is.between?(10, 20).to_s).to eq('10..20')
    expect((is >= 15).to_s).to eq('>= 15')
    expect((is < 30).to_s).to eq('< 30')
  end

  it 'should match conditions' do
    expect(is.between?(10, 20)).not_to be === 9
    expect(is.between?(10, 20)).to be === 15
    expect(is.between?(10, 20)).not_to be === 21

    expect(is >= 15).not_to be === 14
    expect(is >= 15).to be === 15
    expect(is >= 15).to be === 16

    expect(is < 30).to be === 29
    expect(is < 30).not_to be === 30
    expect(is < 30).not_to be === 31
  end
end
