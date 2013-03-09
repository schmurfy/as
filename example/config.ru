require 'rubygems'
require 'bundler/setup'

require 'as'

require File.expand_path('../sniffer', __FILE__)
require File.expand_path('../../specs/support/models', __FILE__)

=begin

User:
  - id
  - login
  - addressbooks: Array[AddressBook]
  - savedstates: Array[SavedState]
  # create_savedtstate()
  # load_savedstate(key)

SavedState:
  - id
  - 

AddressBook:
  - id
  - displayname
  # contacts

Contact:
  - id
  
=end


$user = Testing::User.new(
    id: 1,
    login: 'test.user',
    addressbooks: [
      Testing::AddressBook.new(id: 6, etag: '023', displayname: "Personnel"),
      Testing::AddressBook.new(id: 38, etag: '025', displayname: "ja.directory")
    ],
    savedstates: [
      Testing::SavedState.new(id: '8fbbe2cf', state: AS::State.new())
    ]
  )

class AppAuthentifier < Rack::Auth::Basic
  
  def initialize(app)
    super(app, 'ExampleApp', &method(:authenticate))
  end
  
  def call(env)
    @env = env
    super
  end
    
  def authenticate(login, pass)
    if [login, pass] == ['user', 'pass']
      @env['as.user'] = $user
      true
    else
      false
    end    
  end
end

app = AS::Handler.new()

# authenticate user first
use AppAuthentifier

# encode input and encode result
use AS::WBXML::Middleware

# dump xml
use XMLSniffer

run(app)
