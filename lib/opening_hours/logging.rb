# frozen_string_literal: true

require "logger"

module OpeningHours
  module Logging
    class << self
      attr_writer :logger

      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end
