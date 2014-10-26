require 'spec_helper'
require 'image_optim/runner/option_parser'

describe ImageOptim::Runner::OptionParser do
  before do
    stub_const('OptionParser', ImageOptim::Runner::OptionParser)
  end

  describe :parse! do
    it 'returns empty hash for arguments without options' do
      args = %w[foo bar]
      expect(OptionParser.parse!(args)).to eq({})
      expect(args).to eq(%w[foo bar])
    end

    it 'removes options from arguments' do
      args = %w[-r foo bar]
      OptionParser.parse!(args)
      expect(args).to eq(%w[foo bar])
    end

    describe 'boolean option recursive' do
      %w[-r -R --recursive].each do |flag|
        it "is parsed from #{flag}" do
          args = %W[#{flag} foo bar]
          expect(OptionParser.parse!(args)).to eq(:recursive => true)
          expect(args).to eq(%w[foo bar])
        end
      end
    end

    describe 'numeric option threads' do
      it 'is parsed with space separator' do
        args = %w[--threads 616 foo bar]
        expect(OptionParser.parse!(args)).to eq(:threads => 616)
        expect(args).to eq(%w[foo bar])
      end

      it 'is parsed with equal separator' do
        args = %w[--threads=616 foo bar]
        expect(OptionParser.parse!(args)).to eq(:threads => 616)
        expect(args).to eq(%w[foo bar])
      end

      it 'is parsed with no- prefix' do
        args = %w[--no-threads 616 foo bar]
        expect(OptionParser.parse!(args)).to eq(:threads => false)
        expect(args).to eq(%w[616 foo bar])
      end
    end
  end
end
