require 'anthem/avr/subobject'

module Anthem
  class AVR
    class Zone < SubObject
      PROPERTIES = {}

      def volume_up
        @avr.command("Z#{index}VUP")
      end

      def volume_down
        @avr.command("Z#{index}VDN")
      end

      def percent_volume_up
        @avr.command("Z#{index}PVUP")
      end

      def percent_volume_down
        @avr.command("Z#{index}PVDN")
      end
    end
  end
end
