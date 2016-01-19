class ImageOptim
  # Adds image_optim_processor as class to avoid LegacyTildPreprocessor
  # in sprockets
  class ImageOptimProcessor
    def self.opti_images_options=(options)
      @options = options == true ? {} : (options || {})
      image_optim
    end

    def self.call(input)
      @environment  = input[:environment]
      @uri          = input[:uri]
      @filename     = input[:filename]
      @dirname      = File.dirname(@filename)
      @content_type = input[:content_type]
      @required     = Set.new(input[:metadata][:required])
      @stubbed      = Set.new(input[:metadata][:stubbed])
      @links        = Set.new(input[:metadata][:links])
      @dependencies = Set.new(input[:metadata][:dependencies])

      data = process_source(input[:data])

      {:data => data,
       :required => @required,
       :stubbed => @stubbed,
       :links => @links,
       :dependencies => @dependencies,
       :charset => nil}
    end

    def self.process_source(data)
      image_optim.optimize_image_data(data) || data
    end

    def self.image_optim
      @image_optim ||= ImageOptim.new(@options)
    end
  end
end
