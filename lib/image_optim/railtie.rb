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
      next if app.config.assets.compress == false
      next if app.config.assets.image_optim == false

      register_preprocessor(app)
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

      app.assets.register_preprocessor 'image/gif', :image_optim, &processor
      app.assets.register_preprocessor 'image/jpeg', :image_optim, &processor
      app.assets.register_preprocessor 'image/png', :image_optim, &processor
      app.assets.register_preprocessor 'image/svg+xml', :image_optim, &processor
    end
  end
end
