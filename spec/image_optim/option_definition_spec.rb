# frozen_string_literal: true

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
          expect(subject.value(nil, :abc => nil)).to eq(nil)
        end
      end

      context 'when option is set' do
        it 'returns value' do
          expect(subject.value(nil, :abc => 123)).to eq(123)
        end
      end
    end

    context 'when proc given' do
      subject do
        # not using &:inspect due to ruby Bug #13087
        # to_s is just to calm rubocop
        described_class.new('abc', :def, 'desc'){ |o| o.inspect.to_s }
      end

      context 'when option not provided' do
        it 'returns default passed through proc' do
          expect(subject.value(nil, {})).to eq(':def')
        end
      end

      context 'when option is nil' do
        it 'returns nil passed through proc' do
          expect(subject.value(nil, :abc => nil)).to eq('nil')
        end
      end

      context 'when option is set' do
        it 'returns value passed through proc' do
          expect(subject.value(nil, :abc => 123)).to eq('123')
        end
      end
    end

    context 'when proc with arity 2 given' do
      subject do
        described_class.new('abc', :def, 'desc'){ |a, b| [a.inspect, b] }
      end

      context 'when option not provided' do
        it 'returns default passed through proc' do
          expect(subject.value(nil, {})).to eq([':def', subject])
        end
      end

      context 'when option is nil' do
        it 'returns nil passed through proc' do
          expect(subject.value(nil, :abc => nil)).to eq(['nil', subject])
        end
      end

      context 'when option is set' do
        it 'returns value passed through proc' do
          expect(subject.value(nil, :abc => 123)).to eq(['123', subject])
        end
      end
    end
  end

  describe '#default_description' do
    context 'when default is not a string' do
      subject{ described_class.new('abc', :def, 'desc') }

      it 'returns inspected value in backticks' do
        expect(subject.default_description).to eq('`:def`')
      end
    end

    context 'when default is a string' do
      subject{ described_class.new('abc', '`1`', 'desc') }

      it 'returns it as is' do
        expect(subject.default_description).to eq('`1`')
      end
    end
  end
end
