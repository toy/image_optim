# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/cmd'

describe ImageOptim::Cmd do
  include CapabilityCheckHelpers

  before do
    stub_const('Cmd', ImageOptim::Cmd)
  end

  def expect_int_exception(&block)
    expect(&block).to raise_error(SignalException) do |error|
      expect(error.message.to_s).to match(/INT|#{Signal.list['INT']}/)
    end
  end

  describe '.run' do
    it 'returns process success status' do
      expect(Cmd.run('sh -c "exit 0"')).to eq(true)
      expect($CHILD_STATUS.exitstatus).to eq(0)

      expect(Cmd.run('sh -c "exit 1"')).to eq(false)
      expect($CHILD_STATUS.exitstatus).to eq(1)

      expect(Cmd.run('sh -c "exit 66"')).to eq(false)
      expect($CHILD_STATUS.exitstatus).to eq(66)
    end

    it 'accepts a block that yields the pid' do
      expect(
        Cmd.run('sh -c "exit 66"') do |pid|
          expect(pid.is_a?(Integer)).to eq(true)
        end
      ).to eq(false)
    end

    it 'raises SignalException if process terminates after signal' do
      skip 'signals are not supported' unless signals_supported?
      expect_int_exception do
        Cmd.run('kill -s INT $$')
      end
    end
  end

  describe '.capture' do
    it 'calls ` and returns result' do
      output = double
      expect(Cmd).to receive(:`).with('cmd arg arg+').and_return(output)
      allow(Cmd).to receive(:check_status!)
      expect(Cmd.capture('cmd arg arg+')).to eq(output)
    end

    it 'returns output' do
      expect(Cmd.capture('echo test')).to eq("test\n")
      expect($CHILD_STATUS.exitstatus).to eq(0)

      expect(Cmd.capture('printf more && sh -c "exit 1"')).to eq('more')
      expect($CHILD_STATUS.exitstatus).to eq(1)

      expect(Cmd.capture('sh -c "exit 66"')).to eq('')
      expect($CHILD_STATUS.exitstatus).to eq(66)
    end

    it 'raises SignalException if process terminates after signal' do
      skip 'signals are not supported' unless signals_supported?
      expect_int_exception do
        Cmd.capture('kill -s INT $$')
      end
    end
  end
end
