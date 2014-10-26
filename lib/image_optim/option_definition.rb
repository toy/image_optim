class ImageOptim
  # Hold information about an option
  class OptionDefinition
    attr_reader :name, :default, :type, :description, :proc

    def initialize(name, default, type_or_description, description = nil, &proc)
      if type_or_description.is_a?(Class)
        type = type_or_description
      else
        type, description = default.class, type_or_description
      end

      @name = name.to_sym
      @description = description.to_s
      @default, @type, @proc = default, type, proc
    end
  end
end
