# frozen_string_literal: true

require 'anthem/avr'
require 'logger'

module Anthem
  class << self
    def logger
      @logger ||= Logger.new($stdout)
    end
  end
end
