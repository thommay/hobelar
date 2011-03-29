class Hobelar
  class Parsers
    class GetFilter < Hobelar::Parsers

      attr_reader :response

      def initialize
        super
        @response[:rules] = []
      end

      def start_element(name, attrs = [])
        super

        case name
        when "filterset"
          @in_fset = true
        when "rule"
          @type = attr_value("type", attrs)
          @module = attr_value("module", attrs)
          @metric = attr_value("metric", attrs)
        end
      end

      def end_element(name)
        case name
        when "filterset"
          @in_fset = false
        when "rule"
          @response[:rules] << {:type => @type, :module => @module, :metric => @metric}
        end
      end
    end
  end
end
