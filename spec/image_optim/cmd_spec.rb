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
    it 'calls system and returns result' do
      status = double
      expect(Cmd).to receive(:system).with('cmd', 'arg').and_return(status)
      allow(Cmd).to receive(:check_status!)
      expect(Cmd.run('cmd', 'arg')).to eq(status)
    end

    it 'returns process success status' do
      expect(Cmd.run('sh -c "exit 0"')).to eq(true)
      expect($CHILD_STATUS.exitstatus).to eq(0)

      expect(Cmd.run('sh -c "exit 1"')).to eq(false)
      expect($CHILD_STATUS.exitstatus).to eq(1)

      expect(Cmd.run('sh -c "exit 66"')).to eq(false)
      expect($CHILD_STATUS.exitstatus).to eq(66)
    end

    it 'raises SignalException if process terminates after signal' do
      skip 'signals are not supported' unless signals_supported?
      expect_int_exception do
        Cmd.run('kill -s INT $$')
      end
    end
  end

  describe '.run_with_timeout' do
    it 'calls spawn and returns status' do
      expect(Cmd.run_with_timeout(20, 'sh -c "exit 0"')).to eq(true)
      expect($CHILD_STATUS.exitstatus).to eq(0)

      [1, 66].each do |status|
        expect(Cmd.run_with_timeout(20, "sh -c \"exit #{status}\"")).
          to eq(false)

        expect($CHILD_STATUS.exitstatus).to eq(status)
      end
    end

    it 'raises Timeout::Error if process timeouts' do
      expect{ Cmd.run_with_timeout(0.001, 'sleep 1') }.
        to raise_error(Timeout::Error)
    end

    it 'calls system if timeout is <= zero' do
      expect(Cmd.run_with_timeout(0, 'sh -c "sleep 0.001; exit 0"')).to eq(true)

      expect(Cmd.run_with_timeout(-1, 'sh -c "sleep 0.001; exit 1"')).
        to eq(false)
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
