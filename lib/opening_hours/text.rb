# frozen_string_literal: true

module OpeningHours
  class Text
    def initialize(**attributes)
      @text = attributes[:text]
    end
    attr_reader :text
  end
end
