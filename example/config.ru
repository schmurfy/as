require 'rubygems'
require 'bundler/setup'

require 'rack/fiber_pool'
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

$addr1 = Testing::AddressBook.new(id: 6, etag: '023', displayname: "Personnel", contacts: [
    Testing::Contact.new(id: 5, etag: 'a95P', firstname: 'A', lastname: 'B'),
    Testing::Contact.new(id: 89, etag: 'Y95d', firstname: 'Roger', lastname: 'Rabbit'),
    Testing::Contact.new(id: 68, etag: '996P', firstname: 'Lucy', lastname: 'Liu')
  ])

$user = Testing::User.new(
    id: 1,
    login: 'test.user',
    addressbooks: [
      $addr1#,
      # Testing::AddressBook.new(id: 38, etag: '025', displayname: "ja.directory")
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

use Rack::FiberPool, size: 20

# authenticate user first
use AppAuthentifier

# encode input and encode result
use AS::WBXML::Middleware

# dump xml
use XMLSniffer

run(app)
