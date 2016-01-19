require 'image_optim'
require 'image_optim/image_optim_processor'

class ImageOptim
  # Adds image_optim as preprocessor for gif, jpeg, png and svg images
  class Railtie < Rails::Railtie
    config.before_configuration do |app|
      worker_names = ImageOptim::Worker.klasses.map(&:bin_sym)
      app.config.assets.image_optim =
        ActiveSupport::OrderedOptions.new do |hash, key|
          if worker_names.include?(key.to_sym)
            hash[key] = ActiveSupport::OrderedOptions.new
          end
        end
    end

    initializer 'image_optim.initializer' do |app|
      register_preprocessor(app) if register_preprocessor?(app)
    end

    def register_preprocessor?(app)
      return if app.config.assets.compress == false
      return if app.config.assets.image_optim == false

      true
    end

    def options(app)
      if app.config.assets.image_optim == true
        {}
      else
        app.config.assets.image_optim || {}
      end
    end

    def register_preprocessor(app)
      ImageOptim::ImageOptimProcessor.opti_images_options = options(app)

      if defined?(Sprockets::Processor)
        processor = proc do |_context, data|
          ImageOptim::ImageOptimProcessor.process_source(data)
        end
        app.assets.register_preprocessor 'image/gif', :image_optim, &processor
        app.assets.register_preprocessor 'image/jpeg', :image_optim, &processor
        app.assets.register_preprocessor 'image/png', :image_optim, &processor
        app.assets.register_preprocessor 'image/svg+xml', :image_optim,
                                         &processor
      else
        app.config.assets.configure do |env|
          env.register_preprocessor 'image/gif', :image_optim,
                                    ImageOptim::ImageOptimProcessor
          env.register_preprocessor 'image/jpeg', :image_optim,
                                    ImageOptim::ImageOptimProcessor
          env.register_preprocessor 'image/png', :image_optim,
                                    ImageOptim::ImageOptimProcessor
          env.register_preprocessor 'image/svg+xml', :image_optim,
                                    ImageOptim::ImageOptimProcessor
        end
      end
    end
  end
end
