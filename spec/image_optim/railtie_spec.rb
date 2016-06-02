require 'spec_helper'

describe 'ImageOptim::Railtie' do
  require 'rails/all'
  require 'image_optim/railtie'

  def init_rails_app
    Class.new(Rails::Application) do
      # Rails 4 requires application class to have name
      define_singleton_method :name do
        'Dummy'
      end

      config.active_support.deprecation = :stderr
      config.eager_load = false

      config.logger = Logger.new('/dev/null')

      config.assets.tap do |assets|
        assets.enabled = true
        assets.version = '1.0'
        assets.cache_store = :null_store
        assets.paths = %w[spec/images]

        assets.delete(:compress)
      end

      yield config if block_given?
    end.initialize!
  end

  after do
    Rails.application = nil
  end

  describe 'initialization' do
    it 'initializes by default' do
      expect(ImageOptim).to receive(:new)
      init_rails_app
    end

    it 'initializes if config.assets.image_optim is nil' do
      expect(ImageOptim).to receive(:new)
      init_rails_app do |config|
        config.assets.image_optim = nil
      end
    end

    it 'does not initialize if config.assets.image_optim is false' do
      expect(ImageOptim).not_to receive(:new)
      init_rails_app do |config|
        config.assets.image_optim = false
      end
    end

    it 'does not initialize if config.assets.compress is false' do
      expect(ImageOptim).not_to receive(:new)
      init_rails_app do |config|
        config.assets.compress = false
      end
    end

    describe 'options' do
      it 'initializes with empty hash by default' do
        expect(ImageOptim).to receive(:new).with({})
        init_rails_app
      end

      it 'initializes with empty hash if config.assets.image_optim is true' do
        expect(ImageOptim).to receive(:new).with({})
        init_rails_app do |config|
          config.assets.image_optim = true
        end
      end

      it 'initializes with empty hash if config.assets.image_optim is nil' do
        expect(ImageOptim).to receive(:new).with({})
        init_rails_app do |config|
          config.assets.image_optim = nil
        end
      end

      it 'initializes with hash assigned to config.assets.image_optim' do
        hash = double
        expect(ImageOptim).to receive(:new).with(hash)
        init_rails_app do |config|
          config.assets.image_optim = hash
        end
      end

      it 'is possible to set individual options' do
        hash = {:config_paths => 'config/image_optim.yml'}
        expect(ImageOptim).to receive(:new).with(hash)
        init_rails_app do |config|
          config.assets.image_optim.config_paths = 'config/image_optim.yml'
        end
      end

      it 'is possible to set individual worker options' do
        hash = {:advpng => {:level => 3}}
        expect(ImageOptim).to receive(:new).with(hash)
        init_rails_app do |config|
          expect(config.assets.image_optim.advpng).to eq({})
          config.assets.image_optim.advpng.level = 3
        end
      end

      it 'is not possible to set unknown worker options' do
        expect(ImageOptim).to receive(:new).with({})
        init_rails_app do |config|
          expect(config.assets.image_optim.unknown).to eq(nil)
          expect do
            config.assets.image_optim.unknown.level = 3
          end.to raise_error(NoMethodError)
        end
      end
    end
  end

  describe 'optimizing assets' do
    before do
      stub_const('Path', ImageOptim::Path)
    end

    %w[
      icecream.gif
      lena.jpg
      rails.png
      test.svg
    ].each do |asset_name|
      it "optimizes #{asset_name}" do
        asset = init_rails_app.assets.find_asset(asset_name)

        asset_data = asset.source
        original = Path.convert(asset.pathname)

        expect(asset_data).to be_smaller_than(original)

        Path.temp_file_path %W[spec .#{original.image_format}] do |temp|
          temp.write(asset_data)

          expect(temp).to be_similar_to(original, 0)
        end
      end
    end
  end
end if ENV['RAILS_VERSION']
