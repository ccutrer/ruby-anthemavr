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
      def custom_message(message)
        lines = message.split("\n")[0..3]

        # auto line wrap if given a single line
        if lines.length == 1 && lines[0].length > 32
          original = lines[0]
          lines = []
          while lines.length <= 3 do
            break if original.empty?

            # find the max length that fits
            # this method preserves interior spaces
            i = original.length
            loop do
              break if i < 32 || i.nil?

              i = original.rindex(/\s/, i - 1)
            end
            if i.nil?
              lines << original[0...32]
              original.clear
            else
              lines << original.slice!(0..i).strip
            end
          end
        end

        lines.each_with_index do |line, i|
          @avr.command("Z1MSG#{i}#{line[0..32]}")
        end
      end

      def resolution
        return "#{horizontal_resolution}x#{vertical_resolution}" if horizontal_resolution.to_i != 0 && vertical_resolution.to_i != 0

        "no_input"
      end
    end
  end
end
