require 'nokogiri/xml/sax/document'

class Hobelar
  class Parsers < Nokogiri::XML::SAX::Document

    def initialize    
      @response = {}
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
    end

  end
end

require 'hobelar/parsers/getcheck.rb'
