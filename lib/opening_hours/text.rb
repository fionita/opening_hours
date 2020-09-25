module OpeningHours
  class Text
    def initialize(**attributes)
      @attributes = attributes.merge(type: "Text")

      @attributes
    end
    attr_reader :attributes

    def text
      attributes[:text]
    end
  end
end
