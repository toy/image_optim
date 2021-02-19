# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/worker/oxipng'
require 'image_optim/path'

describe ImageOptim::Worker::Oxipng do
  describe 'strip option' do
    subject{ described_class.new(ImageOptim.new, options) }

    let(:options){ {} }
    let(:src){ instance_double(ImageOptim::Path, copy: nil) }
    let(:dst){ instance_double(ImageOptim::Path) }

    before do
      oxipng_bin = instance_double(ImageOptim::BinResolver::Bin)
      allow(subject).to receive(:resolve_bin!).
        with(:oxipng).and_return(oxipng_bin)

      allow(subject).to receive(:optimized?)
    end

    context 'by default' do
      it 'should add --strip all to arguments' do
        expect(subject).to receive(:execute) do |_bin, *args|
          expect(args.join(' ')).to match(/(^| )--strip all($| )/)
        end

        subject.optimize(src, dst)
      end
    end

    context 'when strip is disabled' do
      let(:options){ {strip: false} }

      it 'should not add --strip all to arguments' do
        expect(subject).to receive(:execute) do |_bin, *args|
          expect(args.join(' ')).not_to match(/(^| )--strip all($| )/)
        end

        subject.optimize(src, dst)
      end
    end
  end

  describe '#optimized?' do
    let(:src){ instance_double(ImageOptim::Path, src_options) }
    let(:dst){ instance_double(ImageOptim::Path, dst_options) }
    let(:src_options){ {size: 10} }
    let(:dst_options){ {size?: 9} }
    let(:instance){ described_class.new(ImageOptim.new, instance_options) }
    let(:instance_options){ {} }

    subject{ instance.optimized?(src, dst) }

    context 'when interlace option is enabled' do
      let(:instance_options){ {interlace: true} }

      context 'when dst is empty' do
        let(:dst_options){ {size?: nil} }
        it{ is_expected.to be_falsy }
      end

      context 'when dst is not empty' do
        let(:dst_options){ {size?: 20} }
        it{ is_expected.to be_truthy }
      end
    end

    context 'when interlace option is disabled' do
      let(:instance_options){ {interlace: false} }

      context 'when dst is empty' do
        let(:dst_options){ {size?: nil} }
        it{ is_expected.to be_falsy }
      end

      context 'when dst is greater than or equal to src' do
        let(:dst_options){ {size?: 10} }
        it{ is_expected.to be_falsy }
      end

      context 'when dst is less than src' do
        let(:dst_options){ {size?: 9} }
        it{ is_expected.to be_truthy }
      end
    end
  end
end
