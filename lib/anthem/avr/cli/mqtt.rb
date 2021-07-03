# frozen_string_literal: true

require 'homie-mqtt'

module Anthem
  class AVR
    module CLI
      class MQTT
        attr_reader :avr, :homie

        def initialize(avr, homie)
          @avr = avr
          @homie = homie

          # wait until we know how many inputs we have
          loop do
            break if avr.input_count

            sleep 0.5
          end

          avr.set_notifier do |object, property_name, value|
            if property_name == :input_count
              publish_objects(Input)
              homie.init do
                ((value + 1)..30).each do |i|
                  homie.remove_node("input#{i}")
                end
              end
              next
            end

            node_name = object.class.name.split('::').last.downcase
            node_name = 'zone' if node_name == 'zone1'
            node_name << object.index.to_s if object.respond_to?(:index)
            node = homie[node_name]
            next unless node # might not be registered yet

            property = node[property_name.to_s.gsub('_', '-')]
            next unless property # might not be registered yet

            property.value = value

            if %i[horizontal_resolution vertical_resolution].include?(property_name)
              property = node['resolution']
              property.value = avr.zones[0].resolution
            end
          end

          [AVR, Profile, Zone].each do |klass|
            publish_objects(klass)
          end

          node = homie['avr']
          node.property('insert-input', 'Insert input at index', :integer, retained: false, format: 1..30) do |value|
            avr.insert_input(value)
          end

          node.property('delete-input', 'Delete input at index', :integer, retained: false, format: 1..30) do |value|
            avr.delete_input(value)
          end

          publish_objects(Input)

          homie.publish

          loop do
            begin
              avr.update
            rescue StandardError => e
              puts "failed updating: #{e}"
            end
            sleep 1
          end
        end

        def publish_objects(klass)
          klass_name = klass.name.split('::').last
          objects = klass == AVR ? [avr] : avr.send(:"#{klass_name.downcase}s")
          objects.each do |o|
            id = "#{klass_name.downcase}#{o.index unless klass == AVR}"
            name = klass_name.dup
            name << " #{o.index}" unless klass == AVR
            next if homie[id]

            homie.node(id, name, klass_name) do |n|
              o.class.properties.each do |(pname, property)|
                next if pname == :input_count

                setter = o.method(:"#{pname}=") if o.respond_to?(:"#{pname}=")
                kwargs = {}
                kwargs[:format] = property[:range]
                kwargs[:format] = AVR.const_get(property[:enum], false).compact if property[:enum]
                kwargs[:unit] = property[:unit]
                if o.respond_to?(pname)
                  value = o.send(pname)
                else
                  kwargs[:retained] = false
                end
                n.property(pname.to_s.gsub('_', '-'), pname, property[:datatype], value, **kwargs, &setter)
              end
              n.property('resolution', 'Video Resolution', :string, o.resolution) if id == 'zone1'
            end
          end
        end
      end
    end
  end
end
