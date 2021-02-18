module Anthem
  class AVR
    class SubObject
      attr_reader :index

      def initialize(avr, index)
        @avr = avr
        @index = index
      end

      def inspect
        useful_ivs = instance_variables - [:@avr]
        ivs = useful_ivs.map { |iv| "#{iv}=#{instance_variable_get(iv).inspect}" }
        "#<#{self.class.name} #{ivs.join(', ')}>"
      end  
    end
  end
end
