require 'excon'
require 'nokogiri'
require 'hobelar/exceptions'
require 'hobelar/parsers'

class Hobelar

  unless const_defined?(:VERSION)
    VERSION = "0.0.4"
  end

  attr_accessor :noit, :cert, :key
  attr_reader :connect

  def initialize(noit, cert, key, ca_file, opts={})
    @noit = noit
    @cert = cert
    @key = key
    @ca_file = ca_file
    Excon.defaults[:ssl_ca_file] = @ca_file
    Excon.ssl_verify_peer = false if opts[:no_peer]
    @connect = Excon.new(noit, {:client_cert => @cert, :client_key => @key })
  end

  def get_check(uuid, path=nil)
    p = path ? "/checks/show/#{path}/#{uuid}" : "/checks/show/#{uuid}" 
    request({:method=>"GET", :path=>p, :parser => Hobelar::Parsers::GetCheck.new})
  end

  def set_check(uuid, attrs, path=nil)
    p = path ? "/checks/set/#{path}/#{uuid}" : "/checks/set/#{uuid}" 
    if (c = attrs.delete(:config))
      if c.has_key?(:inherit)
        config = "<config inherit='#{c[:inherit]}'>"
        c.delete(:inherit)
      else
        config = "<config>"
      end
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
    body += config if config
    body += "</check>"

    request({:method=>"PUT", :path=>p, :body => body, :parser => Hobelar::Parsers::GetCheck.new, :expects =>200})
  end

  def del_check(uuid, path=nil)
    p = path ? "/checks/delete/#{path}/#{uuid}" : "/checks/delete/#{uuid}" 
    request({:method=>"DELETE", :path=>p})
  end

  def get_filter(set, path=nil)
    p = path ? "/filters/show/#{path}/#{set}" : "/filters/show/#{set}" 
    request({:method=>"GET", :path=>p, :parser => Hobelar::Parsers::GetFilter.new})
  end
  
  def set_filter(set, rules, path=nil)
    p = path ? "/filters/set/#{path}/#{set}" : "/filters/set/#{set}" 
    r = ""
    rules.each do |rule|
      r += "<rule type=\"#{rule[:type]}\" module=\"#{rule[:module]}\" metric=\"#{rule[:metric]}\" />"
    end

    body = "<?xml version=\"1.0\" encoding=\"utf8\"?><filterset>#{r}</filterset>"
    request({:method=>"PUT", :path=>p, :body => body, :parser => Hobelar::Parsers::GetFilter.new, :expects =>200})
  end
  
  # deleting filters doesn't actually appear to work; the API gives the correct response
  # but nothing happens
  def del_filter(set, path=nil)
    p = path ? "/filters/delete/#{path}/#{set}" : "/filters/delete/#{set}" 
    request({:method=>"DELETE", :path=>p})
  end
  
  def request(params, &block)

    if block_given?
      params[:response_block] = block
    else
      if (parser = params.delete(:parser))
        body = Nokogiri::XML::SAX::PushParser.new(parser)
        params[:response_block] = lambda { |chunk, remaining, total| body << chunk }
      end
    end

    begin
      response = @connect.request(params)
    rescue Excon::Errors::InternalServerError => error
      raise Hobelar::InternalServerError, error.response.body
    end
    
    case response.status
    when 200
      if parser
        body.finish
        response.body = parser.response
      end

      response
    when 404
      raise Hobelar::NotFound, response.body
    when 403
      raise Hobelar::PermissionDenied, response.body
    when 500
      raise Hobelar::InternalServerError, response.body
    end
  end

end
