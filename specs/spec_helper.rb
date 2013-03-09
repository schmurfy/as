require 'rubygems'
require 'bundler/setup'

require 'eetee'

$LOAD_PATH.unshift( File.expand_path('../../lib' , __FILE__) )
require 'as'

require File.expand_path('../support/models', __FILE__)

require 'eetee/ext/mocha'
require 'eetee/ext/rack'
# require 'bacon/ext/em'

# Thread.abort_on_exception = true


def unindent(str)
  spaces = str.scan(/^\s*/).min_by(&:length)
  str.gsub(/^#{spaces}/, "")
end

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
  def as_request(cmd, body, user = "bob", deviceid = "k456", devicetype = "Phone")
    request(:post, "/Microsoft-Server-ActiveSync?Cmd=#{cmd}&User=#{user}&DeviceId=#{deviceid}&DeviceType=#{devicetype}",
        'MS-ASProtocolVersion:' => '14.0',
        'User-Agent' => 'Dummy',
        input: body
      )

  end
  
  def check_header(response, name, value)
    response.headers[name].should != nil
    response.headers[name].should == value
  end
end

EEtee::Context.send(:include, MyHelpers)
