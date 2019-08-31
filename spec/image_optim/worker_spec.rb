# frozen_string_literal: true

require 'spec_helper'
require 'image_optim/worker'
require 'image_optim/bin_resolver'

describe ImageOptim::Worker do
  before do
    stub_const('Worker', ImageOptim::Worker)
    stub_const('BinResolver', ImageOptim::BinResolver)

    # don't add to list of wokers
    allow(ImageOptim::Worker).to receive(:inherited)
  end

  describe '#initialize' do
    it 'expects first argument to be an instanace of ImageOptim' do
      expect do
        Worker.new(double)
      end.to raise_error ArgumentError
    end
  end

  describe '#options' do
    it 'returns a Hash with options' do
      worker_class = Class.new(Worker) do
        option(:one, 1, 'One')
        option(:two, 2, 'Two')
        option(:three, 3, 'Three')
      end

      worker = worker_class.new(ImageOptim.new, :three => '...')

      expect(worker.options).to eq(:one => 1, :two => 2, :three => '...')
    end
  end

  describe '#optimize' do
    it 'raises NotImplementedError' do
      worker = Worker.new(ImageOptim.new, {})

      expect do
        worker.optimize(double, double)
      end.to raise_error NotImplementedError
    end
  end

  describe '#image_formats' do
    {
      'GifOptim' => :gif,
      'JpegOptim' => :jpeg,
      'PngOptim' => :png,
      'SvgOptim' => :svg,
    }.each do |class_name, image_format|
      it "detects if class name contains #{image_format}" do
        worker = stub_const(class_name, Class.new(Worker)).new(ImageOptim.new)
        expect(worker.image_formats).to eq([image_format])
      end
    end

    it 'fails if class name does not contain known type' do
      worker = stub_const('TiffOptim', Class.new(Worker)).new(ImageOptim.new)
      expect{ worker.image_formats }.to raise_error(/can't guess/)
    end
  end

  describe '#inspect' do
    it 'returns inspect String containing options' do
      stub_const('DefOptim', Class.new(Worker) do
        option(:one, 1, 'One')
        option(:two, 2, 'Two')
        option(:three, 3, 'Three')
      end)

      worker = DefOptim.new(ImageOptim.new, :three => '...')

      expect(worker.inspect).to eq('#<DefOptim @one=1, @two=2, @three="...">')
    end
  end

  describe '.inherited' do
    it 'adds subclasses to klasses' do
      base_class = Class.new{ extend ImageOptim::Worker::ClassMethods }
      expect(base_class.klasses.to_a).to eq([])

      worker_class = Class.new(base_class)
      expect(base_class.klasses.to_a).to eq([worker_class])
    end
  end

  describe '.create_all_by_format' do
    it 'passes arguments to create_all' do
      image_optim = double
      options_proc = proc{ true }

      expect(Worker).to receive(:create_all) do |arg, &block|
        expect(arg).to eq(image_optim)
        expect(block).to eq(options_proc)
        []
      end

      Worker.create_all_by_format(image_optim, &options_proc)
    end

    it 'create hash by format' do
      workers = [
        double(:image_formats => [:a]),
        double(:image_formats => [:a, :b]),
        double(:image_formats => [:b, :c]),
      ]

      expect(Worker).to receive(:create_all).and_return(workers)

      worker_by_format = {
        :a => [workers[0], workers[1]],
        :b => [workers[1], workers[2]],
        :c => [workers[2]],
      }

      expect(Worker.create_all_by_format(double)).to eq(worker_by_format)
    end
  end

  describe '.create_all' do
    def worker_double(override = {})
      stubs = {:resolve_used_bins! => nil, :run_order => 0}.merge(override)
      instance_double(Worker, stubs)
    end

    def worker_class_doubles(workers)
      workers.map{ |worker| class_double(Worker, :init => worker) }
    end

    let(:image_optim){ double(:allow_lossy => false) }

    it 'creates all workers for which options_proc returns true' do
      workers = Array.new(3){ worker_double }
      klasses = worker_class_doubles(workers)
      options_proc = proc do |klass|
        klass == klasses[1] ? {:disable => true} : {}
      end

      allow(Worker).to receive(:klasses).and_return(klasses)

      expect(Worker.create_all(image_optim, &options_proc)).
        to eq([workers[0], workers[2]])
    end

    it 'handles workers initializing multiple instances' do
      workers = [
        worker_double,
        [worker_double, worker_double, worker_double],
        worker_double,
      ]
      klasses = worker_class_doubles(workers)

      allow(Worker).to receive(:klasses).and_return(klasses)

      expect(Worker.create_all(image_optim){ {} }).
        to eq(workers.flatten)
    end

    describe 'with missing workers' do
      let(:workers) do
        %w[a b c c].map do |bin|
          worker = worker_double
          unless bin == 'b'
            allow(worker).to receive(:resolve_used_bins!).
              and_raise(BinResolver::BinNotFound, "not found #{bin}")
          end
          worker
        end
      end
      let(:klasses){ worker_class_doubles(workers) }

      before do
        allow(Worker).to receive(:klasses).and_return(klasses)
      end

      describe 'if skip_missing_workers is true' do
        it 'shows deduplicated warnings and returns resolved workers ' do
          allow(image_optim).to receive(:skip_missing_workers).and_return(true)

          expect(Worker).to receive(:warn).once.with('not found a')
          expect(Worker).to receive(:warn).once.with('not found c')

          expect(Worker.create_all(image_optim){ {} }).to eq([workers[1]])
        end
      end

      describe 'if skip_missing_workers is false' do
        it 'fails with a joint exception of deduplicated messages' do
          allow(image_optim).to receive(:skip_missing_workers).and_return(false)

          expect do
            Worker.create_all(image_optim){ {} }
          end.to raise_error(BinResolver::Error, [
            'Bin resolving errors:',
            'not found a',
            'not found c',
          ].join("\n"))
        end
      end
    end

    it 'orders workers by run_order' do
      run_orders = [10, -10, 0, 0, 0, 10, -10]
      workers = run_orders.map do |run_order|
        worker_double(:run_order => run_order)
      end
      klasses_list = worker_class_doubles(workers)

      [
        klasses_list,
        klasses_list.reverse,
        klasses_list.shuffle,
      ].each do |klasses|
        allow(Worker).to receive(:klasses).and_return(klasses)

        expected_order = klasses.map(&:init).sort_by.with_index do |worker, i|
          [worker.run_order, i]
        end

        expect(Worker.create_all(image_optim){ {} }).to eq(expected_order)
      end
    end

    describe 'passing allow_lossy' do
      it 'passes allow_lossy if worker has such attribute' do
        klasses = worker_class_doubles([worker_double, worker_double])

        allow(Worker).to receive(:klasses).and_return(klasses)

        klasses[0].send(:attr_reader, :allow_lossy)
        expect(klasses[0]).to receive(:init).
          with(image_optim, hash_including(:allow_lossy))
        expect(klasses[1]).to receive(:init).
          with(image_optim, hash_not_including(:allow_lossy))

        Worker.create_all(image_optim){ {} }
      end

      it 'allows overriding per worker' do
        klasses = worker_class_doubles([worker_double, worker_double])
        options_proc = proc do |klass|
          klass == klasses[1] ? {:allow_lossy => :b} : {}
        end

        allow(Worker).to receive(:klasses).and_return(klasses)

        klasses.each{ |klass| klass.send(:attr_reader, :allow_lossy) }
        expect(klasses[0]).to receive(:init).
          with(image_optim, hash_including(:allow_lossy => false))
        expect(klasses[1]).to receive(:init).
          with(image_optim, hash_including(:allow_lossy => :b))

        Worker.create_all(image_optim, &options_proc)
      end
    end
  end

  describe '.option' do
    it 'runs option block in context of worker' do
      stub_const('Abc', Class.new(Worker) do
        option(:test, 1, 'Test context') do |_v|
          some_instance_method
        end
      end)

      expect_any_instance_of(Abc).
        to receive(:some_instance_method).and_return(20)
      expect(Abc.new(ImageOptim.new).test).to eq(20)
    end

    it 'returns instance of OptionDefinition' do
      definition = nil
      Class.new(Worker) do
        definition = option(:test, 1, 'Test'){ |v| v }
      end

      expect(definition).to be_an(ImageOptim::OptionDefinition)
      expect(definition.name).to eq(:test)
      expect(definition.default).to eq(1)
    end
  end
end
