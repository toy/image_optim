# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/cmd'
require 'image_optim/timer'

describe ImageOptim::Cmd do
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

    it 'raises SignalException if process terminates after signal', skip: SkipConditions[:signals_support] do
      expect_int_exception do
        Cmd.run('kill -s INT $$')
      end
    end

    context 'with timeout' do
      it 'returns process success status' do
        expect(Cmd.run('sh -c "exit 0"', timeout: 1)).to eq(true)

        expect(Cmd.run('sh -c "exit 1"', timeout: 1)).to eq(false)

        expect(Cmd.run('sh -c "exit 66"', timeout: 1)).to eq(false)
      end

      it 'returns process success status when timeout is instance of ImageOptim::Timer' do
        timeout = ImageOptim::Timer.new(1.0)
        expect(Cmd.run('sh -c "exit 0"', timeout: timeout)).to eq(true)
      end

      it 'raises SignalException if process terminates after signal', skip: SkipConditions[:signals_support] do
        expect_int_exception do
          Cmd.run('kill -s INT $$', timeout: 1)
        end
      end

      it 'raises TimeoutExceeded if process does not exit until timeout' do
        expect do
          Cmd.run('sleep 10', timeout: 0)
        end.to raise_error(ImageOptim::Errors::TimeoutExceeded)
      end

      it 'does not leave zombie threads' do
        expect do
          begin
            Cmd.run('sleep 10', timeout: 0)
          rescue ImageOptim::Errors::TimeoutExceeded
            # noop
          end
        end.not_to change{ Thread.list }
      end

      it 'receives TERM', skip: SkipConditions[:signals_support] do
        waiter = double
        allow(Process).to receive(:detach).once{ |pid| @pid = pid; waiter }
        allow(waiter).to receive(:join){ sleep 0.1; nil }

        expect do
          Cmd.run('sleep 5', timeout: 0.1)
        end.to raise_error(ImageOptim::Errors::TimeoutExceeded)

        expect(Process.wait2(@pid).last.termsig).to eq(Signal.list['TERM'])
      end

      it 'receives KILL if it does not react on TERM', skip: SkipConditions[:signals_support] do
        waiter = double
        allow(Process).to receive(:detach).once{ |pid| @pid = pid; waiter }
        allow(waiter).to receive(:join){ sleep 0.1; nil }

        expect do
          Cmd.run('trap "" TERM; sleep 5', timeout: 0.1)
        end.to raise_error(ImageOptim::Errors::TimeoutExceeded)

        expect(Process.wait2(@pid).last.termsig).to eq(Signal.list['KILL'])
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

    it 'raises SignalException if process terminates after signal', skip: SkipConditions[:signals_support] do
      expect_int_exception do
        Cmd.capture('kill -s INT $$')
      end
    end
  end
end
