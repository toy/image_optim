require 'spec_helper'
require 'image_optim/worker'
require 'image_optim/bin_resolver'

describe ImageOptim::Worker do
  before do
    stub_const('Worker', ImageOptim::Worker)
    stub_const('BinResolver', ImageOptim::BinResolver)
  end

  describe :optimize do
    it 'raises NotImplementedError' do
      image_optim = ImageOptim.new
      worker = Worker.new(image_optim, {})

      expect do
        worker.optimize(double, double)
      end.to raise_error NotImplementedError
    end
  end

  describe :create_all_by_format do
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

  describe :create_all do
    def worker_double(override = {})
      stubs = {:resolve_used_bins! => nil, :run_order => 0}.merge(override)
      instance_double(Worker, stubs)
    end

    let(:image_optim){ double(:allow_lossy => false) }

    it 'creates all workers for which options_proc returns true' do
      workers = Array.new(3){ worker_double }
      klasses = workers.map{ |worker| double(:init => worker) }
      options_proc = proc{ |klass| klass != klasses[1] ? {} : false }

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
      klasses = workers.map{ |worker| double(:init => worker) }

      allow(Worker).to receive(:klasses).and_return(klasses)

      expect(Worker.create_all(image_optim){ {} }).
        to eq(workers.flatten)
    end

    describe 'with missing workers' do
      let(:workers) do
        Array.new(3) do |i|
          worker = worker_double
          unless i == 1
            allow(worker).to receive(:resolve_used_bins!).
              and_raise(BinResolver::BinNotFound, "not found #{i}")
          end
          worker
        end
      end
      let(:klasses){ workers.map{ |worker| double(:init => worker) } }

      before do
        allow(Worker).to receive(:klasses).and_return(klasses)
      end

      describe 'if skip_missing_workers is true' do
        define :bin_not_found do |message|
          match do |error|
            error.is_a?(BinResolver::BinNotFound) && error.message == message
          end
        end

        it 'shows warnings and returns resolved workers ' do
          allow(image_optim).to receive(:skip_missing_workers).and_return(true)

          expect(Worker).to receive(:warn).
            once.with(bin_not_found('not found 0'))
          expect(Worker).to receive(:warn).
            once.with(bin_not_found('not found 2'))

          expect(Worker.create_all(image_optim){ {} }).
            to eq([workers[1]])
        end
      end

      describe 'if skip_missing_workers is false' do
        it 'fails with a joint exception' do
          allow(image_optim).to receive(:skip_missing_workers).and_return(false)

          expect do
            Worker.create_all(image_optim){ {} }
          end.to raise_error(BinResolver::Error, /not found 0\nnot found 2/)
        end
      end
    end

    it 'orders workers by run_order' do
      image_optim = double(:allow_lossy => false)
      run_orders = [10, -10, 0, 0, 0, 10, -10]
      workers = run_orders.map do |run_order|
        worker_double(:run_order => run_order)
      end
      klasses_list = workers.map{ |worker| double(:init => worker) }

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
  end

  describe :option do
    it 'runs option block in context of worker' do
      # don't add Abc to list of wokers
      allow(ImageOptim::Worker).to receive(:inherited)

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
      # don't add Abc to list of wokers
      allow(ImageOptim::Worker).to receive(:inherited)

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
