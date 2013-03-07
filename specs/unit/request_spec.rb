require File.expand_path('../../spec_helper', __FILE__)


describe 'Request' do
  before do
    
  end
  
  
  # POST /Microsoft-Server- ActiveSync?Cmd=Sync&User=rmjones&DeviceId=v140Device&DeviceType=SmartPhone HTTP/1.1 Content-Type: application/vnd.ms-sync.wbxml
  # MS-ASProtocolVersion: 14.0
  # User-Agent: ASOM
  # Host: Contoso.com
  # Accept-Language: en-us
  # Content-Length: 868
  should 'decode url' do
    env = Rack::MockRequest.env_for('/Microsoft-Server-ActiveSync?Cmd=Sync&User=mrjones&DeviceId=v140Device&DeviceType=SmartPhone&toto=42',
        'REQUEST_METHOD'       => 'POST',
        'MS-ASProtocolVersion' => "14.0"
      )
    
    req = AS::Request.load_from_rack(env)
    req.class.should == AS::SyncRequest
    req.user.should == 'mrjones'
    req.device_type.should == 'SmartPhone'
    req.device_id.should == 'v140Device'
    req.params.should == {'toto' => '42'}
  end
  
  
  # should 'decode base64 encoded url' do
  #   env = Rack::MockRequest.env_for('/Microsoft-Server-ActiveSync?jAAJBAp2MTQwRGV2aWNlAApTbWFydFBob25l',
  #       'REQUEST_METHOD'       => 'POST'
  #     )
    
  #   req = AS::Request.load_from_rack(env)

  # end
end
