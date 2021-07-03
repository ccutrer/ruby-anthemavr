# frozen_string_literal: true

module Anthem
  class BaseObject
    class << self
      def add_property(property)
        @properties ||= {}
        @properties[property[:name]] = property
      end

      def properties
        return {} if self == BaseObject

        @properties ||= {}
        @properties.merge(superclass.properties)
      end
    end
  end
end
