require 'image_optim'

class ImageOptim
  # Adds image_optim as preprocessor for gif, jpeg, png and svg images
  class Railtie < Rails::Railtie
    initializer 'image_optim.initializer' do |app|
      register_preprocessor(app) if register_preprocessor?(app)
    end

    def register_preprocessor?(app)
      return if app.config.assets.compress == false
      return if app.config.assets.image_optim == false

      app.assets
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
