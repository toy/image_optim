require 'spec_helper'
require 'image_optim/option_definition'

describe ImageOptim::OptionDefinition do
  describe 'initialization' do
    context 'when type is not specified explicitly' do
      subject{ described_class.new('abc', :def, 'desc') }

      describe '#name' do
        it{ expect(subject.name).to eq(:abc) }
      end

      describe '#default' do
        it{ expect(subject.default).to eq(:def) }
      end

      describe '#type' do
        it{ expect(subject.type).to eq(Symbol) }
      end

      describe '#description' do
        it{ expect(subject.description).to eq('desc') }
      end
    end

    context 'when type is specified explicitly' do
      subject{ described_class.new('abc', :def, Hash, 'desc') }

      describe '#name' do
        it{ expect(subject.name).to eq(:abc) }
      end

      describe '#default' do
        it{ expect(subject.default).to eq(:def) }
      end

      describe '#type' do
        it{ expect(subject.type).to eq(Hash) }
      end

      describe '#description' do
        it{ expect(subject.description).to eq('desc') }
      end
    end
  end

  describe '#value' do
    context 'when proc not given' do
      subject{ described_class.new('abc', :def, 'desc') }

      context 'when option not provided' do
        it 'returns default' do
          expect(subject.value(nil, {})).to eq(:def)
        end
      end

      context 'when option is nil' do
        it 'returns nil' do
          expect(subject.value(nil, {:abc => nil})).to eq(nil)
        end
      end

      context 'when option is set' do
        it 'returns value' do
          expect(subject.value(nil, {:abc => 123})).to eq(123)
        end
      end
    end

    context 'when proc given' do
      subject{ described_class.new('abc', :def, 'desc'){ |v| v.inspect } }

      context 'when option not provided' do
        it 'returns default passed through proc' do
          expect(subject.value(nil, {})).to eq(':def')
        end
      end

      context 'when option is nil' do
        it 'returns nil passed through proc' do
          expect(subject.value(nil, {:abc => nil})).to eq('nil')
        end
      end

      context 'when option is set' do
        it 'returns value passed through proc' do
          expect(subject.value(nil, {:abc => 123})).to eq('123')
        end
      end
    end
  end
end
