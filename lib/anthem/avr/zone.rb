# frozen_string_literal: true

require "anthem/avr/subobject"

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
      add_property(name: :custom_message, datatype: :string)

      def custom_message=(message)
        message = message.tr("\t", " ")
                         .gsub(%r{[^a-zA-Z0-9./ \n-]}, "")
                         .strip

        lines = []
        # auto line wrap
        while lines.length <= 4
          break if message.empty?

          i = message.index("\n")
          # find the max length that fits
          # this method preserves interior spaces
          i ||= message.length
          loop do
            break if i.nil? || i < 32

            i = message.rindex(/\s/, i - 1)
          end
          # force an in-word break if necessary
          i ||= 31
          lines << message.slice!(0..i).strip
          message.strip!
        end

        lines.each_with_index do |line, index|
          @avr.command("Z1MSG#{index}#{line[0..32]}")
        end
        (lines.length..3).each do |index|
          @avr.command("Z1MSG#{index}")
        end
      end

      def resolution
        if horizontal_resolution.to_i != 0 && vertical_resolution.to_i != 0
          return "#{horizontal_resolution}x#{vertical_resolution}"
        end

        "no_input"
      end
    end
  end
end
