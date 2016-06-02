require 'spec_helper'
require 'image_optim/worker/optipng'
require 'image_optim/path'

describe ImageOptim::Worker::Optipng do
  describe 'strip option' do
    subject{ described_class.new(ImageOptim.new, options) }

    let(:options){ {} }
    let(:optipng_version){ '0.7' }
    let(:src){ instance_double(ImageOptim::Path, :copy => nil) }
    let(:dst){ instance_double(ImageOptim::Path) }

    before do
      optipng_bin = instance_double(ImageOptim::BinResolver::Bin)
      allow(subject).to receive(:resolve_bin!).
        with(:optipng).and_return(optipng_bin)
      allow(optipng_bin).to receive(:version).
        and_return(ImageOptim::BinResolver::SimpleVersion.new(optipng_version))

      allow(subject).to receive(:optimized?)
    end

    context 'by default' do
      it 'should add -strip all to arguments' do
        expect(subject).to receive(:execute) do |_bin, *args|
          expect(args.join(' ')).to match(/(^| )-strip all($| )/)
        end

        subject.optimize(src, dst)
      end
    end

    context 'when strip is disabled' do
      let(:options){ {:strip => false} }

      it 'should not add -strip all to arguments' do
        expect(subject).to receive(:execute) do |_bin, *args|
          expect(args.join(' ')).not_to match(/(^| )-strip all($| )/)
        end

        subject.optimize(src, dst)
      end
    end

    context 'when optipng version is < 0.7' do
      let(:optipng_version){ '0.6.999' }

      it 'should not add -strip all to arguments' do
        expect(subject).to receive(:execute) do |_bin, *args|
          expect(args.join(' ')).not_to match(/(^| )-strip all($| )/)
        end

        subject.optimize(src, dst)
      end
    end
  end
end
