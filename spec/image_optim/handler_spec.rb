$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/handler'

describe ImageOptim::Handler do
  it 'should use original as source for first conversion '\
      'and two temp files for further conversions' do
    original = double(:original)
    allow(original).to receive(:temp_path) do
      fail 'temp_path called unexpectedly'
    end

    handler = ImageOptim::Handler.new(original)
    temp_a = double(:temp_a)
    temp_b = double(:temp_b)
    expect(original).to receive(:temp_path).once.and_return(temp_a)
    expect(original).to receive(:temp_path).once.and_return(temp_b)

    # first unsuccessful run
    handler.process do |src, dst|
      expect([src, dst]).to eq([original, temp_a]); false
    end
    expect(handler.result).to be_nil

    # first successful run
    handler.process do |src, dst|
      expect([src, dst]).to eq([original, temp_a]); true
    end
    expect(handler.result).to eq(temp_a)

    # second unsuccessful run
    handler.process do |src, dst|
      expect([src, dst]).to eq([temp_a, temp_b]); false
    end
    expect(handler.result).to eq(temp_a)

    # second successful run
    handler.process do |src, dst|
      expect([src, dst]).to eq([temp_a, temp_b]); true
    end
    expect(handler.result).to eq(temp_b)

    # third successful run
    handler.process do |src, dst|
      expect([src, dst]).to eq([temp_b, temp_a]); true
    end
    expect(handler.result).to eq(temp_a)

    # forth successful run
    handler.process do |src, dst|
      expect([src, dst]).to eq([temp_a, temp_b]); true
    end
    expect(handler.result).to eq(temp_b)

    expect(temp_a).to receive(:unlink).once
    handler.cleanup
    handler.cleanup
  end
end
