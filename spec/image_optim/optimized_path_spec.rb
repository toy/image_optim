require 'image_optim/optimized_path'

describe ImageOptim::OptimizedPath do
  describe '#initialize' do
    context 'when second argument is original' do
      subject{ described_class.new('a', 'b') }

      before do
        allow_any_instance_of(ImageOptim::ImagePath).
          to receive(:size).and_return(616)
      end

      it 'delegates to optimized path as ImagePath' do
        is_expected.to eq(ImageOptim::ImagePath.new('a'))
      end

      it 'returns original path as ImagePath for original' do
        expect(subject.original).to eq(ImageOptim::ImagePath.new('b'))
      end

      it 'returns original size for original_size' do
        expect(subject.original_size).to eq(616)
      end
    end

    context 'when second argument is size' do
      subject{ described_class.new('a', 616) }

      it 'delegates to optimized path as ImagePath' do
        is_expected.to eq(ImageOptim::ImagePath.new('a'))
      end

      it 'returns optimized path as ImagePath for original' do
        expect(subject.original).to eq(ImageOptim::ImagePath.new('a'))
      end

      it 'returns size for original_size' do
        expect(subject.original_size).to eq(616)
      end
    end

    context 'when no second argument' do
      subject{ described_class.new('a') }

      it 'delegates to optimized path as ImagePath' do
        is_expected.to eq(ImageOptim::ImagePath.new('a'))
      end

      it 'returns nil for original' do
        expect(subject.original).to eq(nil)
      end

      it 'returns nil for original_size' do
        expect(subject.original_size).to eq(nil)
      end
    end
  end
end
