# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/handler'

describe ImageOptim::Handler do
  before do
    stub_const('Handler', ImageOptim::Handler)
  end

  it 'uses original as source for first conversion '\
      'and two temp files for further conversions' do
    original = double(:original)
    allow(original).to receive(:respond_to?).with(:temp_path).and_return(true)

    handler = Handler.new(original)
    temp_a = double(:temp_a)
    temp_b = double(:temp_b)
    expect(original).to receive(:temp_path).and_return(temp_a, temp_b)

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

  describe '.for' do
    it 'yields instance, runs cleanup and returns result' do
      original = double
      handler = double
      result = double

      expect(Handler).to receive(:new).
        with(original).and_return(handler)
      expect(handler).to receive(:process)
      expect(handler).to receive(:cleanup)
      expect(handler).to receive(:result).and_return(result)

      expect(Handler.for(original, &:process)).to eq(result)
    end

    it 'cleans up if exception is raised' do
      original = double
      handler = double

      expect(Handler).to receive(:new).
        with(original).and_return(handler)
      expect(handler).to receive(:cleanup)

      expect do
        Handler.for(original) do
          fail 'hello'
        end
      end.to raise_error 'hello'
    end
  end
end
