require "config"
require "opening_hours/version"
require "opening_hours/logging"
require "opening_hours/text"
require "active_support/core_ext/hash"

module OpeningHours
  class Error < StandardError; end

  class << self
    WEEK_DAYS = %w[
      Monday
      Tuesday
      Wednesday
      Thursday
      Friday
      Saturday
      Sunday
    ].freeze

    # 'openingHoursSpecificationSet' => [
    #   {
    #     'name' => 'Whatever'
    #     'validFrom' => date,
    #     'validThrough' => date,
    #     'openingHoursSpecification' => [
    #       {
    #         'dayOfWeek' => 'Monday',
    #         'opens' => '17:00',
    #         'closes' => '22:00',
    #         'allDay' => false
    #       }
    #     ]
    #   }
    # ],

    def parse(entity)
      entity = entity.with_indifferent_access

      answer_from_sets        = from_sets(entity)
      answer_from_description = from_description(entity)

      if answer_from_sets.blank? && answer_from_description.blank?
        return [Text.new(text: I18n.t("no_opening_hours_set"))]
      end

      [answer_from_sets, answer_from_description].compact
    end

    def from_description(entity)
      ohd = entity.dig("opening_hours_description_translations", I18n.locale)

      return if ohd.blank?

      Text.new(text: ohd)
    end

    def from_sets(entity)
      return if entity["openingHoursSpecificationSet"].blank?

      set = select_opening_hours_set([entity["openingHoursSpecificationSet"]].flatten)
      return if set.blank?

      opening_hours = set["openingHoursSpecification"]

      OpeningHours::Logging.logger.info("Using openingHours: #{opening_hours}")

      if set["validFrom"].blank? || set["validThrough"].blank?
        text = []
      else
        start_date = Time.parse(set["validFrom"])
        end_date   = Time.parse(set["validThrough"])

        text = [I18n.t(
          "valid_from_to",
          start_date: start_date.strftime("%d.%m.%Y"),
          end_date: end_date.strftime("%d.%m.%Y")
        )]
      end

      if opening_hours.present?
        wdays = [opening_hours].flatten.group_by { |x| x["dayOfWeek"] }

        WEEK_DAYS.each do |day_of_week|
          opening_hours = wdays.present? ? wdays[day_of_week] : nil

          text << opening_hours_text(opening_hours, day_of_week)
        end
      else
        text << I18n.t("no_opening_hours")
      end

      Text.new(text: text.compact.join("\n"))
    end

    def select_opening_hours_set(opening_hours_sets)
      return opening_hours_sets.first if always?(opening_hours_sets)

      opening_hours_sets.find do |opening_hours_set|
        start_date = Date.parse(opening_hours_set["validFrom"] || Date.today.to_s)
        end_date   = Date.parse(opening_hours_set["validThrough"] || Date.today.to_s)
        range      = (start_date..end_date)

        range.cover?(Date.today)
      end
    end

    def always?(opening_hours_sets)
      return false if opening_hours_sets.size > 1

      set = opening_hours_sets.first

      set["validFrom"].blank? && set["validThrough"].blank?
    end

    def opening_hours_text(opening_hours, day_of_week)
      return "#{I18n.t(day_of_week)}: #{I18n.t('closed')}" if opening_hours.blank?
      return "#{I18n.t(day_of_week)}: #{I18n.t('24_hours_opened')}" if all_day?(opening_hours)

      hours = working_hours(opening_hours)

      return "#{I18n.t(day_of_week)}: #{I18n.t('closed')}" if hours.blank?

      "#{I18n.t(day_of_week)}: #{hours}"
    end

    def all_day?(opening_hours)
      opening_hours.select { |o| o["allDay"] == true }.present?
    end

    def working_hours(opening_hours)
      return if opening_hours.blank?

      hours  = []
      ranges = hours_range(opening_hours)
      ranges.compact.sort_by(&:first).each do |range|
        hours << "#{range.first.strftime('%H:%M')} - #{range.last.strftime('%H:%M')}"
      end

      hours = hours.join(", ")
    end

    def hours_range(opening_hours)
      date = Date.today

      opening_hours.map do |day|
        opens  = Time.parse("#{date.to_date} #{day['opens']}")
        closes = Time.parse("#{date.to_date} #{day['closes']}")

        opens..closes
      end
    end
  end
end
