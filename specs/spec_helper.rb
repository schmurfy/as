require 'rubygems'
require 'bundler/setup'

require 'eetee'
require 'factory_girl'

$LOAD_PATH.unshift( File.expand_path('../../lib' , __FILE__) )
require 'as'

require File.expand_path('../support/models', __FILE__)
require File.expand_path('../factories', __FILE__)

require 'eetee/ext/mocha'
require 'eetee/ext/rack'
require 'eetee/ext/em'

# Thread.abort_on_exception = true


class SpecWithUserMiddleware
  def initialize(app, user)
    @app = app
    @user = user
  end
  
  def call(env)
    env['as.user'] = @user
    @app.call(env)
  end
end


module MyHelpers
  def unindent(str)
    spaces = str.scan(/^\s*/).min_by(&:length)
    str.gsub(/^#{spaces}/, "")
  end

  
  def build_contact_xml(c, indent_level, parent_name = 'ApplicationData')
    parent_node = Ox::Element.new(parent_name)
    c.to_xml(parent_node)
    result = Ox.dump(parent_node)
    
    indent = ' ' * indent_level
    lines = result.split("\n")[1..-1]
    
    lines = Array(lines[0]) + lines[1..-1].map{|line| "#{indent}#{line}" }
    lines.join("\n")
  end

  
  def as_request(cmd, body, opts = {})
    user = opts.delete(:user) || 'bob'
    deviceid = opts.delete(:deviceid) || 'k456'
    devicetype = opts.delete(:devicetype) || 'Phone'
    user_agent = opts.delete(:user_agent) || 'Dummy'
    
    request(:post, "/Microsoft-Server-ActiveSync?Cmd=#{cmd}&User=#{user}&DeviceId=#{deviceid}&DeviceType=#{devicetype}",
        'MS-ASProtocolVersion:' => '14.0',
        'HTTP_USER_AGENT'       => user_agent,
        input: body
      )

  end
  
  def check_header(response, name, value)
    response.headers[name].should != nil
    response.headers[name].should == value
  end
  
  def build(*args)
    FactoryGirl.build(*args)
  end
end

EEtee::Context.send(:include, MyHelpers)
