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
        return "#{horizontal_resolution}x#{vertical_resolution}" if horizontal_resolution.to_i != 0 && vertical_resolution.to_i != 0

        "no_input"
      end
    end
  end
end
