$:.unshift File.expand_path('../../../../lib', __FILE__)
require 'rspec'
require 'image_optim/bin_resolver/simple_version'

describe ImageOptim::BinResolver::SimpleVersion do
  def v(str)
    ImageOptim::BinResolver::SimpleVersion.new(str)
  end

  it 'should compare versions' do
    expect(v '1.17').to be > '0'
    expect(v '1.17').to be > '0.1'
    expect(v '1.17').to be > '0.9'
    expect(v '1.17').to be > '1.9'
    expect(v '1.17').to be < '1.17.1'
    expect(v '1.17').to be < '1.99'
    expect(v '1.17').to be < '2.1'
  end

  it 'should normalize versions' do
    variations = %w[1 01 1.0 1.00 1.0.0 1.0.0.0]
    variations.each do |a|
      variations.each do |b|
        expect(v a).to eq(b)
      end
    end
  end

  it 'should convert objects' do
    expect(v 1.17).to eq('1.17')
    expect(v '1.17').to eq('1.17')
    expect(v(v 1.17)).to eq('1.17')
  end
end
