require 'spec_helper'
require 'image_optim/runner/option_parser'

describe ImageOptim::Runner::OptionParser do
  before do
    stub_const('OptionParser', ImageOptim::Runner::OptionParser)
  end

  def exit_with_status(status)
    raise_error(SystemExit) do |e|
      expect(e.status).to eq(status)
    end
  end

  describe '.parse!' do
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

    it 'stops parsing options after --' do
      args = %w[-- -r foo bar]
      OptionParser.parse!(args)
      expect(args).to eq(%w[-r foo bar])
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

    describe 'help option' do
      it 'prints help text to stdout and exits' do
        parser = OptionParser.new({})
        expect(OptionParser).to receive(:new).and_return(parser)

        help = double
        expect(parser).to receive(:help).and_return(help)

        expect do
          OptionParser.parse!(%w[--help])
        end.to exit_with_status(0) &
               output("#{help}\n").to_stdout
      end
    end

    describe 'wrong option' do
      it 'prints help text to stdout and exits' do
        parser = OptionParser.new({})
        expect(OptionParser).to receive(:new).and_return(parser)

        help = double
        expect(parser).to receive(:help).and_return(help)

        expect do
          OptionParser.parse!(%w[--unknown-option])
        end.to exit_with_status(1) &
               output("invalid option: --unknown-option\n\n#{help}\n").to_stderr
      end
    end
  end

  describe '#help' do
    it 'returns wrapped text' do
      parser = OptionParser.new({})

      allow(parser).to receive(:terminal_columns).and_return(80)

      expect(parser.help.split("\n")).
        to all(satisfy{ |line| line.length <= 80 })
    end
  end
end
