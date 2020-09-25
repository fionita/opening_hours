# frozen_string_literal: true

module OpeningHours
  class Text
    def initialize(**attributes)
      @attr = attributes.merge(type: "Text")
    end

    def text
      @attr[:text]
    end
  end
end
