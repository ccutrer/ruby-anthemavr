require "anthem/avr"
require "logger"

module Anthem
  class << self
    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end