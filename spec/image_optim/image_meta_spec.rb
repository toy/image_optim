# frozen_string_literal: true

require 'image_optim/image_meta'

describe ImageOptim::ImageMeta do
  let(:image_path){ 'spec/images/lena.jpg' }
  let(:non_image_path){ __FILE__ }
  let(:broken_image_path){ 'spec/images/broken_jpeg' }

  describe '.format_for_path' do
    context 'for an image' do
      it 'returns format' do
        expect(described_class.format_for_path(image_path)).
          to eq(:jpeg)
      end
    end

    context 'for broken image' do
      it 'warns and returns nil' do
        expect(described_class).to receive(:warn)

        expect(described_class.format_for_path(broken_image_path)).
          to eq(nil)
      end
    end

    context 'for not an image' do
      it 'does not warn and returns nil' do
        expect(described_class).not_to receive(:warn)

        expect(described_class.format_for_path(non_image_path)).
          to eq(nil)
      end
    end
  end

  describe '.format_for_data' do
    context 'for image data' do
      it 'returns format' do
        expect(described_class.format_for_data(File.read(image_path))).
          to eq(:jpeg)
      end
    end

    context 'for broken image data' do
      it 'warns and returns nil' do
        expect(described_class).to receive(:warn)

        expect(described_class.format_for_data(File.read(broken_image_path))).
          to eq(nil)
      end
    end

    context 'for not an image data' do
      it 'does not warn and returns nil' do
        expect(described_class).not_to receive(:warn)

        expect(described_class.format_for_data(File.read(non_image_path))).
          to eq(nil)
      end
    end
  end
end
