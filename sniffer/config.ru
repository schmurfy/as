require 'rubygems'
require 'bundler/setup'

require 'socket'
require 'net/http'
require 'net/https'
require 'rack'

require 'as'
require 'as/debug/sniffer'
 
Net::HTTP.version_1_2 # Sorry if this causes anyone an issue...
 
module Rack
  class Forwarder
    # General exceptions which may be raised by Net::HTTP
    HttpExceptions = [
      Timeout::Error, EOFError, SystemCallError, SocketError,NoMemoryError,
      IOError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError
    ]
 
    def initialize(host, port=80, ssl = false)
      @host, @port, @ssl = host, port, ssl
    end
 
    # Using the block form has the added advantage of catching the exceptions
    # that could be raised by Net::HTTP for you, otherwise you will have to 
    # handle those yourself.
    def conn
      @conn ||= connect
      if block_given?
        yield @conn
      else
        @conn
      end
    rescue *HttpExceptions
      @conn = connect
      return if defined?(once)
      once = true && retry
    end
 
    # Just a wrapper around Net::HTTP.start effectively, but also sets up
    # use_ssl when specified.
    def connect
      http = Net::HTTP.new @host, @port
      # http.set_debug_output($stdout)
      http.use_ssl = @ssl
      http.start
      http
    end
 
    def call(env)
      rackreq = Rack::Request.new(env)
 
      headers = Rack::Utils::HeaderHash.new
      env.each { |key, value|
        if key =~ /HTTP_(.*)/
          headers[$1] = value
        end
      }
      
      headers['HOST'] = 'contacts.yago.fr'
 
      res = conn { |http|
        m = rackreq.request_method
        case m
        when "GET", "HEAD", "DELETE", "OPTIONS", "TRACE"
          req = Net::HTTP.const_get(m.capitalize).new(rackreq.fullpath, headers)
        when "PUT", "POST"
          req = Net::HTTP.const_get(m.capitalize).new(rackreq.fullpath, headers)
          rackreq.body.rewind
          req.body = rackreq.body.read
          rackreq.body.rewind
        else
          raise "method not supported: #{method}"
        end
        
        http.request(req)
      }
 
      headers = res.to_hash
      headers.delete(headers.keys.grep(/transfer\-encoding/i).first)
 
      [res.code, Rack::Utils::HeaderHash.new(headers), Array(res.body)]
    end
  end 
end

# use Rack::CommonLogger
use WBXMLSniffer
# run Rack::Forwarder.new('contacts.yago.fr', 443, true)
run Rack::Forwarder.new('preprod.tcare.fr', 8080)
