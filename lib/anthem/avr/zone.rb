require 'anthem/avr/subobject'

module Anthem
  class AVR
    class Zone < SubObject
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

    class Zone1 < Zone
      def resolution
        "#{horizontal_resolution}x#{vertical_resolution}" if horizontal_resolution && vertical_resolution
      end
    end
  end
end
