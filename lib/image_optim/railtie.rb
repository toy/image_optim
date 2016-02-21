require 'image_optim'

class ImageOptim
  # Adds image_optim as preprocessor for gif, jpeg, png and svg images
  class Railtie < Rails::Railtie
    MIME_TYPES = %w[
      image/gif
      image/jpeg
      image/png
      image/svg+xml
    ].freeze

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

      @image_optim = ImageOptim.new(options(app))

      register_preprocessor(app)
    end

    def options(app)
      if app.config.assets.image_optim == true
        {}
      else
        app.config.assets.image_optim || {}
      end
    end

    def optimize_image_data(data)
      @image_optim.optimize_image_data(data) || data
    end

    def register_preprocessor(app)
      processor = proc do |_context, data|
        optimize_image_data(data)
      end

      MIME_TYPES.each do |mime_type|
        app.assets.register_preprocessor mime_type, :image_optim, &processor
      end
    end
  end
end
