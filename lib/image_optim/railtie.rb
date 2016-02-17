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
      if register_preprocessor?(app)
        options = build_options(app)
        if app.assets
          register_preprocessor(app.assets, options)
        else
          app.config.assets.configure do |env|
            register_preprocessor(env, options)
          end
        end
      end
    end

    def register_preprocessor?(app)
      app.config.assets.compress != false &&
        app.config.assets.image_optim != false
    end

    def build_options(app)
      if app.config.assets.image_optim == true
        {}
      else
        app.config.assets.image_optim || {}
      end
    end

    def register_preprocessor(env, options)
      image_optim = ImageOptim.new(options)

      processor = proc do |_context, data|
        image_optim.optimize_image_data(data) || data
      end

      env.register_preprocessor 'image/gif', :image_optim, &processor
      env.register_preprocessor 'image/jpeg', :image_optim, &processor
      env.register_preprocessor 'image/png', :image_optim, &processor
      env.register_preprocessor 'image/svg+xml', :image_optim, &processor
    end
  end
end
