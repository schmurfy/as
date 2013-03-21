require 'ox'
require 'rack/request'
require 'coderay'

class XMLSniffer
  PREFIX = " " * 4
  
  def initialize(app)
    @app = app
  end
  
  def decode_body(data)
    data
  end
  
  def call(env)
    ret = nil
    ret = @app.call(env)
    
  ensure
    request = Rack::Request.new(env)
    puts "\n\n\n*** REQUEST ( #{request.request_method} #{request.path} ) ***"
    request.body.rewind
    dump_headers(env)
    
    body = request.body.read
    request.body.rewind
    
    unless body.empty?
      dump_xml(body)
    end
    
    if ret
      val = ret[1].values_at('content-length', 'Content-Length').compact.first
      content_length = Array(val).first.to_i
      
      if content_length > 0
        puts "\n    --- RESPONSE BODY (#{ret[0]}) ---"
        ret[1].each do |name, value|
          puts "#{name} = #{value}"
        end
        
        tmp = ret[2]
        
        if tmp.is_a?(Rack::BodyProxy)
          tmp = tmp.body
        end
        
        if tmp.is_a?(Array)
          tmp = tmp[0]
        end
                
        if tmp.is_a?(String)
          body = tmp
        elsif tmp.is_a?(StringIO)
          body = tmp.read
          tmp.rewind
        else
          raise "wtf: #{tmp}"
        end
        
        dump_xml(body)
      else
        puts "\n    --- EMPTY RESPONSE BODY (#{ret[0]}) ---"
        ret[1].each do |name, value|
          puts "#{name} = #{value}"
        end
      end
    end
    
    ret
  end
  
private
  def dump_headers(env)
    extract_headers(env).each do |name, value|
      puts "#{name} = #{value}"
    end
  end

  def dump_xml(str)
    doc = Ox.parse( decode_body(str) )
    source = Ox.dump(doc)
    puts ""
    puts CodeRay.scan(source, :xml).term
  rescue SyntaxError, Ox::ParseError
    puts "\n#{str}"
  end
  
  def extract_headers(env)
    headers = env.select {|k,v| k.start_with?('HTTP_') || (k[0].upcase == k[0])}
    headers.map do |pair|
      [pair[0].ljust(20), pair[1]]
    end
  end
  
end

require 'as/wbxml'

class WBXMLSniffer < XMLSniffer
  def initialize(app, language = :activesync)
    @app = app
    @decoder = AS::WBXML::Decoder.new
    @decoder.set_language(language)
    super(app)
  end
  
  def decode_body(data)
    @decoder.decode(data)
  end
  
end

