require 'image_optim'

class ImageOptim
  class Railtie < Rails::Railtie
    initializer 'image_optim.initializer' do |app|
      if app.config.assets.compress != false && app.config.assets.image_optim != false && app.assets

        options = if app.config.assets.image_optim == true
          {}
        else
          app.config.assets.image_optim || {}
        end

        image_optim = ImageOptim.new(options)

        processor = proc do |context, data|
          image_optim.optimize_image_data(data) || data
        end

        app.assets.register_preprocessor 'image/gif', :image_optim, &processor
        app.assets.register_preprocessor 'image/jpeg', :image_optim, &processor
        app.assets.register_preprocessor 'image/png', :image_optim, &processor
        app.assets.register_preprocessor 'image/svg+xml', :image_optim, &processor

      end
    end
  end
end
