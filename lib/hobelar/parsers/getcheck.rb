class Hobelar
  class Parsers
    class GetCheck < Nokogiri::XML::SAX::Document

      attr_reader :response

      def initialize
        @response = {}
        @response[:attributes] = {}
        @response[:config] = {}
        @response[:state] = {}
        @response[:state][:metrics] = {}
      end

      def characters(string)
        @value ||= ''
        @value << string.strip
      end

      def attr_value(name, attrs)
        (entry = attrs.detect {|a,v| a == name }) && entry.last
      end
      
      def start_element(name, attrs = [])
        @value = nil

        case name
        when "attributes"
          @in_attrs = true
        when "config"
          @in_config = true
        when "state"
          # the state set contains an element called state. This is unhelpful.
          if @in_state 
            @bloody_state = true
          else
            @in_state = true
          end
        when "metrics"
          @in_metrics = true
        when "module","period","timeout","filterset"
          @inherited = attr_value("inherited", attrs)
        when "last_run"
          begin
            @time_now = DateTime.strptime(attr_value("now", attrs), "%s")
          rescue
            @time_now = nil
          end
        when "metric"
          @m_name = attr_value("name", attrs)
          @m_type = attr_value("type", attrs)
        end
      end

      def end_element(name)
        case name
        when "attributes"
          @in_attrs = false
        when "config"
          @in_config = false
        when "state"
          if @bloody_state
            @bloody_state = false
            @response[:state][:state] = @value
          else
            @in_state = false
          end
        when "metrics"
          @in_metrics = false
        when "uuid"
          @response[:uuid] = @value if @in_attrs
        when "name"
          @response[:name] = @value if @in_attrs
        when "module"
          @response[:module] = @value if @in_attrs
        when "target"
          @response[:target] = @value if @in_attrs
        when "last_run"
          @response[:now] = @time_now
          begin
            @response[:last_run] = DateTime.strptime(@value, "%s")
          rescue
            @response[:last_run] = nil
          end
        else
          if @in_attrs
            @response[:attributes][name.to_sym] = @value
          elsif @in_config
            @response[:config][name.to_sym] = @value
          elsif @in_state && @in_metrics
            if @m_name
              @response[:state][:metrics][@m_name.to_sym] = @value
            else
              @response[:state][:metrics][name.to_sym] = @value
            end
            @m_name = nil
          elsif @in_state
            @response[:state][name.to_sym] = @value
          end
        end
      end
    end
  end
end
