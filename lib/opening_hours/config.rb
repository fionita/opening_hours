require "i18n"

module OpeningHours
  module Config
    I18n.load_path = Dir[File.expand_path("config/locales") + "/*.yml"]
    I18n.default_locale = :de
  end
end
