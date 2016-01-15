require 'image_optim'

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

      if defined?(Sprockets::Rails) && Gem::Version.new(Sprockets::Rails::VERSION) >= Gem::Version.new("3.0.0")
        true
      else
        app.assets
      end
    end

    def options(app)
      if app.config.assets.image_optim == true
        {}
      else
        app.config.assets.image_optim || {}
      end
    end

    def register_preprocessor(app)
      image_optim = ImageOptim.new(options(app))

      processor = proc do |_context, data|
        image_optim.optimize_image_data(data) || data
      end

      if defined?(Sprockets::Rails) && Gem::Version.new(Sprockets::Rails::VERSION) >= Gem::Version.new("3.0.0")
        app.config.assets.configure do |env|
          env.register_preprocessor 'image/gif', :image_optim, &processor
          env.register_preprocessor 'image/jpeg', :image_optim, &processor
          env.register_preprocessor 'image/png', :image_optim, &processor
          env.register_preprocessor 'image/svg+xml', :image_optim, &processor
        end
      else
        app.assets.register_preprocessor 'image/gif', :image_optim, &processor
        app.assets.register_preprocessor 'image/jpeg', :image_optim, &processor
        app.assets.register_preprocessor 'image/png', :image_optim, &processor
        app.assets.register_preprocessor 'image/svg+xml', :image_optim, &processor
      end

    end
  end
end
