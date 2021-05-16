require 'anthem/baseobject'

module Anthem
  class AVR < BaseObject
  end
end

require 'anthem/avr/input'
require 'anthem/avr/profile'
require 'anthem/avr/zone'

module Anthem
  class AVR < BaseObject
    attr_reader :inputs, :profiles, :zones

    def initialize(port)
      super()

      @port = port

      @inputs = [].freeze
      @zones = [Zone1.new(self, 1), Zone.new(self, 2)].freeze
      @profiles = (1..4).map do |i|
        Profile.new(self, i)
      end.freeze

      connect
    end

    def close
      # this will cause the read thread to die
      @io&.close
      @io = nil
    end

    def set_notifier(&block)
      @notifier = block
    end

    def insert_input(i)
      raise ArgumentError, "input number must be between 1 and 30" unless (1..30).include?(i)

      command("IIAI#{i}")
      refresh_inputs
    end

    def delete_input(i)
      raise ArgumentError, "input number must be between 1 and 30" unless (1..30).include?(i)

      command("IDAI#{i}")
      refresh_inputs
    end

    def update
      unless zones[0].power
        assign(zones[0], :video_format, :no_input)
        assign(zones[0], :horizontal_resolution, 0)
        assign(zones[0], :vertical_resolution, 0)
        assign(zones[0], :audio_channels, :no_input)
        assign(zones[0], :audio_format, :no_input)
        assign(zones[0], :audio_bitrate, 0)
        assign(zones[0], :audio_sample_rate, 0)
        assign(zones[0], :audio_bitdepth, 0)
        assign(zones[0], :audio_description, "No Signal")
        assign(zones[0], :audio_rate_description, "No Signal")

        return
      end

      MANUAL_UPDATES.each do |cmd|
        request(cmd)
      end
    end

    def inspect
      useful_ivs = instance_variables - %i[@inputs @profiles @zones @read_thread]
      ivs = useful_ivs.map { |iv| "#{iv}=#{instance_variable_get(iv).inspect}" }
      "#<#{self.class.name} #{ivs.join(', ')}>"
    end

    VIDEO_INPUT_RESOLUTION = [
      :no_input,
      :other,
      '1080p60',
      '1080p50',
      '1080p24',
      '1080i60',
      '1080i50',
      '720p60',
      '720p50',
      '576p50',
      '576i50',
      '480p60',
      '480i60',
      '3D',
      '2160p60',
      '2160p50',
      '2160p24',
    ].freeze

    AUDIO_CHANNELS = [
      :no_input,
      :other,
      "Mono",
      "Stereo",
      "5.1",
      "7.1",
      "Atmos",
      "DTS-X",
    ].freeze

    AUDIO_FORMAT = [
      :no_input,
      'Analog',
      'PCM',
      'Dolby Digital',
      'DSD',
      'DTS',
      'Atmos',
      'DTS-X',
    ].freeze

    FRONT_SPEAKER_ASSIGNMENT = [
      'Front',
      'Zone 2',
      'Front Wide',
      'Height 3',
    ].freeze

    SURROUND_SPEAKER_ASSIGNMENT = [
      'Surround',
      'Zone 2',
      'Height 3',
    ].freeze

    BACK_SPEAKER_ASSIGNMENT = [
      'Back',
      'Zone 2',
      'Zone 2 On Demand',
      'Front Wide',
      'Front Bi-Amp',
    ].freeze

    HEIGHT1_SPEAKER_ASSIGNMENT = [
      'Height 1',
      'Zone 2',
      'Front Bi-Amp',
    ].freeze

    HEIGHT2_SPEAKER_ASSIGNMENT = [
      'Height 2',
      'Zone 2',
      'Front Wide',
      'Front Bi-Amp',
    ].freeze

    HEIGHT_SPEAKER_ROLE = [
      'Height',
      'Back'
    ].freeze

    HEIGHT1_SPEAKER_ROLE = [
      'Front In-Ceiling',
      'Front Dolby',
      'Front On-Wall',
      'Middle In-Ceiling',
      'Middle Dolby',
      'Back In-Ceiling',
      'Back Dolby',
      'Back On_Wall',
      'Off',
    ].freeze

    HEIGHT2_SPEAKER_ROLE = [
      'Middle In-Ceiling',
      'Middle Dolby',
      'Back In-Ceiling',
      'Back Dolby',
      'Back On_Wall',
      'Off',
    ].freeze

    HEIGHT3_SPEAKER_ROLE = [
      'Back In-Ceiling',
      'Back Dolby',
      'Back On_Wall',
      'Off',
    ].freeze

    AUDIO_JACK = [
      nil,
      'HDMI',
      'HDMI ARC',
      'Digital Coaxial 1',
      'Digital Coaxial 2',
      'Digital Optical 1',
      'Digital Optical 2',
      'Digital Optical 3',
      'Analog 1',
      'Analog 2',
      'Analog 3',
      'Analog 4',
      'Analog 5',
      'Streaming',
      'Bluetooth',
    ].freeze

    MONO_PRESET = [
      'Mono',
      'Last Used',
      'All Channel Mono',
    ].freeze

    STEREO_PRESET = [
      'None',
      'Last used',
      'AnthemLogic-Cinema',
      'AnthemLogic-Music',
      'Dolby Surround',
      'DTS Neural:X',
      'DTS Virtual:X',
      'All Channel Stereo',
      'Mono',
      'All Channel Mono',
    ].freeze

    MULTICHANNEL_PRESET = [
      'None',
      'Last Used',
      'Dolby Surround',
      'DTS Neural:X',
      'DTS Virtual:X',
      'All Channel Stereo',
      'Mono',
      'All Channel Mono',
    ].freeze

    LANGUAGE = %w[
      English
      Chinese
      German
      Spanish
      French
      Italian
    ].freeze

    UNITS = %i[
      imperial
      metric
    ].freeze

    ON_SCREEN_DISPLAY = [
      'Off',
      '16:9',
      '2.4:1',
    ].freeze

    FRONT_PANEL_DISPLAY = [
      'All',
      'Volume Only',
    ].freeze

    VOLUME_SCALE = %w[
      Percent
      dB
    ].freeze

    NO_SIGNAL_POWER_OFF = [
      '5 minutes',
      '10 minutes',
      '20 minutes',
      '1 hour',
      '2 hours',
      '6 hours',
      nil,
      'Never'
    ].freeze

    AUDIO_LISTENING_MODE = [
      :none,
      'Anthem Logic - Cinema',
      'Anthem Logic - Music',
      'Dolby Surround',
      'DTS neural:x',
      # "DTS Virtual:X", # same ID as stereo?
      'Stereo',
      'All Channel Stereo',
      'Mono',
      'All-Channel Mono'
    ].freeze

    DOLBY_DIGITAL_DYNAMIC_RANGE = %i[
      normal
      reduced
      late_night
    ].freeze

    PROPERTIES_INTERNAL = [
      { command: 'IDQ' },
      { command: 'IDM', name: :model, datatype: :string, readonly: true },
      { command: 'IDS', name: :software_version, datatype: :string, readonly: true },
      { command: 'DSPIDS', name: :dsp_software_version, datatype: :string, readonly: true },
      { command: 'LCDIDS', name: :lcds_software_version, datatype: :string, readonly: true },
      { command: 'GSN', name: :serial_number, datatype: :string, readonly: true },
      { command: 'IDR', name: :region, datatype: :string, readonly: true },
      { command: 'IDB', name: :software_build_date, datatype: :string, readonly: true },
      { command: 'IDH', name: :hardware_revision, datatype: :string, readonly: true },
      { command: 'NMSVER', name: :networking_module_software_version, datatype: :string, readonly: true },
      { command: 'NMHVER', name: :networking_module_hardware_version, datatype: :string, readonly: true },
      { command: 'RVER', name: :networking_module_release_version, datatype: :string, readonly: true },
      { command: 'RBD', name: :networking_module_release_build_date, datatype: :string, readonly: true },
      { command: 'NMR', name: :networking_module_region, datatype: :string, readonly: true },
      { command: 'WMAC', name: :wifi_mac, datatype: :string, readonly: true },
      { command: 'EMAC', name: :ethernet_mac, datatype: :string, readonly: true },
      { command: 'NMST', name: :network_status, datatype: :string, readonly: true },

      { command: 'ZzVIR', name: :video_format, datatype: :enum, enum: :VIDEO_INPUT_RESOLUTION, readonly: true,
        zone1: true },
      { command: 'ZzIRH', name: :horizontal_resolution, datatype: :integer, readonly: true, zone1: true },
      { command: 'ZzIRV', name: :vertical_resolution, datatype: :integer, readonly: true, zone1: true },
      { command: 'ZzAIC', name: :audio_channels, datatype: :enum, enum: :AUDIO_CHANNELS, readonly: true,
        zone1: true },
      { command: 'ZzAIF', name: :audio_format, datatype: :enum, enum: :AUDIO_FORMAT, readonly: true,
        zone1: true },
      { command: 'ZzBRT', name: :audio_bitrate, datatype: :integer, zero_is_nil: true, unit: 'kbps', readonly: true,
        zone1: true },
      { command: 'ZzSRT', name: :audio_sample_rate, datatype: :integer, zero_is_nil: true, unit: 'kHz', readonly: true,
        zone1: true },
      { command: 'ZzBDP', name: :audio_bitdepth, datatype: :integer, readonly: true, zone1: true },
      { command: 'ZzAIN', name: :audio_description, datatype: :string, readonly: true, zone1: true },
      { command: 'ZzAIR', name: :audio_rate_description, datatype: :string, readonly: true, zone1: true },
      { command: 'ZzSHC', name: :show_custom_message, datatype: :boolean, zone1: true, poll: false },


      { command: 'SSAMF', name: :front_speaker_assignment, datatype: :enum, enum: :FRONT_SPEAKER_ASSIGNMENT },
      { command: 'SSAMS', name: :surround_speaker_assignment, datatype: :enum, enum: :SURROUND_SPEAKER_ASSIGNMENT },
      { command: 'SSAMB', name: :back_speaker_assignment, datatype: :enum, enum: :BACK_SPEAKER_ASSIGNMENT },
      { command: 'SSAMH1', name: :height1_speaker_assignment, datatype: :enum, enum: :HEIGHT1_SPEAKER_ASSIGNMENT },
      { command: 'SSAMH2', name: :height2_speaker_assignment, datatype: :enum, enum: :HEIGHT2_SPEAKER_ASSIGNMENT },

      { command: 'SS3DHL', name: :height_speaker_role, datatype: :enum, enum: :HEIGHT_SPEAKER_ROLE },
      { command: 'SS3DH1', name: :height1_speaker_role, datatype: :enum, enum: :HEIGHT2_SPEAKER_ROLE },
      { command: 'SS3DH2', name: :height2_speaker_role, datatype: :enum, enum: :HEIGHT3_SPEAKER_ROLE },
      { command: 'SS3DH3', name: :height3_speaker_role, datatype: :enum, enum: :HEIGHT3_SPEAKER_ROLE },

      { command: 'SSSPp0', name: :name, datatype: :string, max_length: 16 },
      { command: 'SSSPp1', name: :subwoofer, datatype: :integer },
      { command: 'SSSPp5', name: :front, datatype: :boolean },
      { command: 'SSSPp6', name: :front_wide, datatype: :boolean },
      { command: 'SSSPp7', name: :center, datatype: :boolean },
      { command: 'SSSPp8', name: :surround, datatype: :boolean },
      { command: 'SSSPp9', name: :back, datatype: :boolean },
      { command: 'SSSPpA', name: :height1, datatype: :boolean },
      { command: 'SSSPpB', name: :height2, datatype: :boolean },
      { command: 'SSSPpC', name: :height3, datatype: :boolean },

      # TODO: bass management
      # TODO: listener position
      # TODO: level calibration

      { command: 'ICN', name: :input_count, datatype: :integer },
      { command: 'ISiIN', name: :name, datatype: :string, max_length: 16 },
      { command: 'ISiVID', name: :video_jack, datatype: :integer, zero_is_nil: true },
      { command: 'ISiAIJ', name: :audio_jack, datatype: :enum, enum: :AUDIO_JACK },
      { command: 'ISiCA', name: :convert_analog_audio, datatype: :boolean },
      { command: 'ISiSP', name: :speaker_profile, datatype: :integer, range: 1..4 },
      { command: 'ISiARC', name: :anthem_room_correction, datatype: :boolean },
      { command: 'ISiRF', name: :rumble_filter, datatype: :boolean },
      { command: 'ISiDV', name: :dolby_audio_post_processing, datatype: :boolean },
      { command: 'ISiPM', name: :mono_preset, datatype: :enum, enum: :MONO_PRESET },
      { command: 'ISiPS', name: :stereo_preset, datatype: :enum, enum: :STEREO_PRESET },
      { command: 'ISiPC', name: :multichannel_preset, datatype: :enum, enum: :MULTICHANNEL_PRESET },
      { command: 'ISiLS', name: :lip_sync_delay, datatype: :integer, range: 0..150 },
      { command: 'ISiIT', name: :input_trim, datatype: :float, range: -12.0..12.0 },

      { command: 'GCL', name: :language, datatype: :enum, enum: :LANGUAGE },
      # AVR reports unrecognized?
      # { command: 'GCTZ', name: :time_zone_offset, datatype: :float, range: -12.0..14.0 },
      { command: 'GCBU', name: :beta_updates, datatype: :boolean },
      { command: 'GCDU', name: :units, datatype: :enum, enum: :UNITS },
      { command: 'GCFPB', name: :front_panel_brightness, datatype: :integer, unit: '%', range: 0..100 },
      { command: 'GCWUB', name: :wake_up_brightness, datatype: :integer, unit: '%', range: 0..100 },
      { command: 'GCOSID', name: :on_screen_display_info, datatype: :enum, enum: :ON_SCREEN_DISPLAY },
      { command: 'GCFPDI', name: :front_panel_display_info, datatype: :enum, enum: :FRONT_PANEL_DISPLAY },
      # AVR reports unrecognized?
      # { command: 'GVMVS', name: :volume_scale, datatype: :enum, enum: :VOLUME_SCALE },
      # AVR reports unrecognized?
      # { command: 'GVML', name: :mute_level, datatype: :integer, unit: 'dB', range: -50..-5 },
      { command: 'GCMMV', name: :maximum_volume, datatype: :float, range: -40..+10, unit: 'dB', zone: 1 },
      { command: 'GCZ2MMV', name: :maximum_volume, datatype: :float, range: -40..+10, unit: 'dB', zone: 2 },
      { command: 'GCMPOV', name: :power_on_volume, datatype: :float, range: -90..+10, unit: 'dB', zone: 1 },
      { command: 'GCZ2POV', name: :power_on_volume, datatype: :float, range: -90..+10, unit: 'dB', zone: 2 },
      { command: 'GCMPOI', name: :power_on_input, datatype: :integer, range: 0..30, zone: 1 },
      { command: 'GCZ2POI', name: :power_on_input, datatype: :integer, range: 0..30, zone: 2 },
      { command: 'GCNSPO', name: :no_signal_power_off, datatype: :enum, enum: :NO_SIGNAL_POWER_OFF },
      { command: 'GCRIR', name: :rear_ir, datatype: :boolean },
      { command: 'GCFIR', name: :front_ir, datatype: :boolean },

      # TODO: moar

      { command: 'ZzPOW', name: :power, datatype: :boolean },
      { command: 'ZzINP', name: :input, datatype: :integer, range: 1..30 },
      { command: 'ZzVOL', name: :volume, datatype: :float, range: -90.0..+10.0, step: 0.5, unit: 'dB',
        format: '%+.1f' },
      { command: 'ZzPVOL', name: :volume_percent, datatype: :integer, range: 0..100 },
      { command: 'ZzMUT', name: :mute, datatype: :boolean },

      { command: 'ZzALM', name: :audio_listening_mode, datatype: :enum, enum: :AUDIO_LISTENING_MODE, zone1: true },
      { command: 'ZzDYN', name: :dolby_digital_dynamic_range, datatype: :enum, enum: :DOLBY_DIGITAL_DYNAMIC_RANGE,
        zone1: true },
      { command: 'ZzTON0', name: :bass, datatype: :float, range: -10.0..+10.0, step: 0.5, unit: 'dB', format: '%+.1f',
        zone1: true },
      { command: 'ZzTON1', name: :treble, datatype: :float, range: -10.0..+10.0, step: 0.5, unit: 'dB',
        format: '%+.1f', zone1: true },
      { command: 'ZzBAL', name: :balance, datatype: :float, range: -5.0..+5.0, step: 0.5, unit: 'dB', format: '%+.1f',
        zone1: true }

      # TODO: moar
    ].freeze

    SUB_OBJECT_CLASSES = {
      'i' => Input,
      'p' => Profile,
      'z' => Zone,
    }.freeze

    SUB_OBJECT_COUNTS = {
      'i' => 30,
      'p' => 4,
      'z' => 2,
    }.freeze

    COMMANDS_HASH = {}
    MANUAL_UPDATES = []

    PROPERTIES_INTERNAL.each do |property|
      property.freeze

      sub_object_type = property[:command] =~ /[ipz]/ && $&
      sub_object_klass = SUB_OBJECT_CLASSES[sub_object_type]
      klass = sub_object_klass || self
      klass = Zone1 if klass == Zone && property[:zone1]
      if property[:zone]
        klass = property[:zone] == 1 ? Zone1 : Zone
      end

      count = SUB_OBJECT_COUNTS[sub_object_type] || 1

      (1..count).each do |i|
        next if property[:zone1] && i != 1

        command = property[:command]
        command = command.sub(sub_object_type, i.to_s) if sub_object_type

        COMMANDS_HASH[command] = property
        MANUAL_UPDATES << command if property[:zone1] && property[:poll] != false
      end

      next unless property[:name]

      klass.add_property(property)

      next unless property[:datatype]

      klass.attr_reader property[:name]

      next if property[:readonly]

      case property[:datatype]
      when :boolean
        code = <<-RUBY
          raise ArgumentError, "Expected true or false" unless [true, false].include?(value)
          value = value ? "1" : "0"
        RUBY
      when :integer
        code = <<~RUBY
          raise ArgumentError, "expected integer" unless value.is_a?(Integer)
        RUBY
        code << <<~RUBY if property[:range]
          raise ArgumentError, "expected integer" unless value.is_a?(Integer)
          raise ArgumentError, "value out of valid range #{property[:range].inspect}" unless (#{property[:range].inspect}).include?(value)
        RUBY
      when :float
        code = <<~RUBY
          raise ArgumentError, "expected integer" unless value.is_a?(Numeric)
        RUBY
        code << <<~RUBY if property[:range]
          raise ArgumentError, "value out of valid range #{property[:range].inspect}" unless (#{property[:range].inspect}).include?(value)
        RUBY
        code << <<~RUBY if property[:step]
          raise ArgumentError, "value must be a multiple of #{property[:step]}" unless value % #{property[:step]} == 0
        RUBY
        code << <<~RUBY if property[:format]
          value = #{property[:format].inspect} % value
        RUBY
      when :string
        code = <<~RUBY
          raise ArgumentError, "expected string" unless value.is_a?(String)
          raise ArgumentError, "value is too long" unless value.length < #{property[:max_length]}
        RUBY
      when :enum
        code = <<~RUBY
          raise ArgumentError, "expected one of #{property[:enum]}.join(' ')" unless (value = #{property[:enum]}.index(value))
        RUBY
      else
        raise "Unknown datatype #{property[:datatype].inspect} for #{property[:command]}"
      end

      avr = "@avr." unless klass == self
      command = property[:command].inspect
      command = command.sub(sub_object_type, '#{index}') if sub_object_type # rubocop:disable Lint/InterpolationCheck
      klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{property[:name]}=(value)
          #{code}
          #{avr}command(#{command}, value.to_s)
        end
      RUBY
    end

    # make everything private
    private_constant(*constants.grep(/^[A-Z]+$/))

    def command(command, arg = nil)
      Anthem.logger.debug("Writing #{command}#{arg}")
      @io.write("#{command}#{arg};")
    end

    private

    def connect
      uri = URI.parse(@port)
      @io = case uri.scheme
            when 'tcp'
              require 'socket'
              TCPSocket.new(uri.host, uri.port || 14_999)
            when 'telnet', 'rfc2217'
              require 'net/telnet/rfc2217'
              Net::Telnet::RFC2217.new(uri.host,
                                       port: uri.port || 23,
                                       baud: 115_200,
                                       data_bits: 8,
                                       parity: :none,
                                       stop_bits: 1)
            else
              require 'ccutrer-serialport'
              CCutrer::SerialPort.new(@port,
                                      baud: 115_200,
                                      data_bits: 8,
                                      parity: :none,
                                      stop_bits: 1)
            end
      # populate everything we care about
      COMMANDS_HASH.each do |(cmd, property)|
        request(cmd) if property[:datatype]
      end
      @read_thread = Thread.new { read_thread }
      @read_thread.abort_on_exception = true
    end

    def request(request)
      Anthem.logger.debug("Writing #{request}?")
      @io.write("#{request}?;")
    end

    def refresh_inputs
      request("ICN")
      COMMANDS_HASH.each do |(command, property)|
        next unless property[:command].include?('i')

        request(command)
      end
    end

    def read_thread
      loop do
        command = @io.readline(";")[0..-2]

        if command[0] == '!'
          error_type = command[1]
          command = command[2..-1]
          case error_type
          when 'E' then Anthem.logger.warn("Cannot execute command #{command} at this time")
          when 'I' then Anthem.logger.error("AVR reports unrecognized command #{command}")
          when 'R' then Anthem.logger.error("Out of range: #{command}")
          when 'Z' then Anthem.logger.warn("Cannot execute command #{command} at this time because the zone is off")
          end
          next
        end

        property = nil
        (2..(command.length - 1)).find do |i|
          property = COMMANDS_HASH[command[0..i]]
        end

        unless property
          Anthem.logger.warn("Unrecognized command #{command.inspect}")
          next
        end

        Anthem.logger.debug("Received #{command.inspect}")

        next unless property[:datatype]

        sub_object_type = (property[:command] =~ /[ipz]/) && $&
        sub_objects = case sub_object_type
                      when 'i' then inputs
                      when 'p' then profiles
                      when 'z' then zones
                      else; object = self
                      end

        if sub_object_type
          position = property[:command].index(sub_object_type)
          # for inputs, it can be multiple characters; it's okay to
          # always get both, since the next character is always a non-integer
          # and #to_i will ignore it
          index = command[sub_object_type == 'i' ? position..(position + 1) : position]
          object = sub_objects[index.to_i - 1]
          # we might not have all zones defined
          next unless object
        end

        object = zones[property[:zone] - 1] if property[:zone]

        raw_value = command[property[:command].length..-1]
        value = case property[:datatype]
                when :string; raw_value
                when :boolean; raw_value.to_i == 1
                when :integer; raw_value.to_i
                when :float; raw_value.to_f
                when :enum; self.class.const_get(property[:enum], false)[raw_value.to_i]
                  # else; raise "unknown datatype for #{property[:command]}"
                end

        assign(object, property[:name], value) do
          if property[:name] == :input_count
            @inputs = @inputs.dup
            if input_count > @inputs.length
              @inputs.concat(((@inputs.length + 1)..input_count).map do |i|
                Input.new(self, i)
              end)
            else
              @inputs = @inputs[0...input_count]
            end
            @inputs.freeze
          end
        end
      end
    rescue EOFError => e
      # auto-reconnect
      begin
        Anthem.logger.warn("connection lost, reconnecting...")
        close
        connect
        Anthem.logger.info("reconnected")
      rescue StandardError => e2
        Anthem.logger.error("Could not reconnect: #{e2}")
        raise e
      end
    end

    def assign(object, property, value)
      old_value = object.instance_variable_get(:"@#{property}")
      return if old_value == value

      object.instance_variable_set(:"@#{property}", value)
      yield if block_given?
      @notifier&.call(object, property, value)
    end
  end
end
