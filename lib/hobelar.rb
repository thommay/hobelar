require 'excon'
require 'nokogiri'
require 'hobelar/exceptions'
require 'hobelar/parsers'

class Hobelar

  unless const_defined?(:VERSION)
    VERSION = "0.0.1"
  end

  attr_accessor :noit, :cert, :key
  attr_reader :connect

  def initialize(noit, cert, key, opts={})
    @noit = noit
    @cert = cert
    @key = key
    @connect = Excon.new(noit, {:client_cert => @cert, :client_key => @key })
    Excon.ssl_verify_peer = false if opts[:no_peer]
  end

  def get_check(uuid, path=nil)
    p = path ? "/checks/show/#{path}/#{uuid}" : "/checks/show/#{uuid}" 
    request({:method=>"GET", :path=>p, :parser => Hobelar::Parsers::GetCheck.new})
  end

  def set_check(uuid, attrs, path=nil)
    p = path ? "/checks/set/#{path}/#{uuid}" : "/checks/set/#{uuid}" 
    if (c = attrs.delete(:config))
      puts c
      config = "<config>"
      c.each_pair do |k,v|
        key = k.to_s.downcase
        config += "<#{key}>#{v}</#{key}>"
      end
      config += "</config>"
    end
    attributes = "<attributes>"

    # set some required attributes, without which noit won't bother responding
    attrs = {:period=>"60000", :timeout=>"5000", :filterset=>"default"}.merge(attrs)

    attrs.each_pair do |k,v|
      key = k.to_s.downcase
      attributes += "<#{key}>#{v}</#{key}>"
    end
    attributes += "</attributes>"

    body = "<?xml version=\"1.0\" encoding=\"utf8\"?><check>#{attributes}"
    body += config.nil? ? "<config/>" : config
    body += "</check>"

    request({:method=>"PUT", :path=>p, :body => body, :parser => Hobelar::Parsers::GetCheck.new})
  end

  def del_check(uuid, path=nil)
    p = path ? "/checks/delete/#{path}/#{uuid}" : "/checks/delete/#{uuid}" 
    request({:method=>"DELETE", :path=>p})
  end

  def get_filter(set, path=nil)
  
  end
  
  def set_filter(set, rules, path=nil)
  
  end
  
  def del_filter(set, path=nil)
  
  end
  
  def request(params, &block)

    unless block_given?
      if (parser = params.delete(:parser))
        body = Nokogiri::XML::SAX::PushParser.new(parser)
        block = lambda { |chunk| body << chunk }
      end
    end

    response = @connect.request(params, &block)
    
    case response.status
    when 200
      if parser
        body.finish
        response.body = parser.response
      end

      response
    when 404
      raise Hobelar::NotFound
    when 403
      raise Hobelar::PermissionDenied
    end
  end

end
