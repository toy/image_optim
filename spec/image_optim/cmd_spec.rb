$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'rspec'
require 'image_optim/cmd'

describe ImageOptim::Cmd do
  Cmd = ImageOptim::Cmd

  describe :run do
    it 'calls system and returns result' do
      status = double
      expect(Cmd).to receive(:system).with('cmd', 'arg').and_return(status)
      allow(Cmd).to receive(:check_status!)
      expect(Cmd.run('cmd', 'arg')).to eq(status)
    end

    it 'returns process success status' do
      expect(Cmd.run('sh -c exit\ 0')).to eq(true)
      expect($CHILD_STATUS.exitstatus).to eq(0)

      expect(Cmd.run('sh -c exit\ 1')).to eq(false)
      expect($CHILD_STATUS.exitstatus).to eq(1)

      expect(Cmd.run('sh -c exit\ 66')).to eq(false)
      expect($CHILD_STATUS.exitstatus).to eq(66)
    end

    it 'raises SignalException if process terminates after signal' do
      expect do
        Cmd.run('kill -s INT $$')
      end.to raise_error(SignalException, /INT|#{Signal.list['INT']}/)
    end
  end

  describe :capture do
    it 'calls ` and returns result' do
      output = double
      expect(Cmd).to receive(:`).with('cmd arg arg+').and_return(output)
      allow(Cmd).to receive(:check_status!)
      expect(Cmd.capture('cmd arg arg+')).to eq(output)
    end

    it 'returns output' do
      expect(Cmd.capture('echo test')).to eq("test\n")
      expect($CHILD_STATUS.exitstatus).to eq(0)

      expect(Cmd.capture('printf more; sh -c exit\ 1')).to eq('more')
      expect($CHILD_STATUS.exitstatus).to eq(1)

      expect(Cmd.capture('sh -c exit\ 66')).to eq('')
      expect($CHILD_STATUS.exitstatus).to eq(66)
    end

    it 'raises SignalException if process terminates after signal' do
      expect do
        Cmd.capture('kill -s INT $$')
      end.to raise_error(SignalException, /INT|#{Signal.list['INT']}/)
    end
  end
end
