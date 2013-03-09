require File.expand_path('../../spec_helper', __FILE__)


describe 'Handler' do
  before do
    app = Rack::Builder.new do
      # use XMLSniffer
      run AS::Handler.new
    end
    
    serve_app(app)
  end
  
  def check_header(response, name, value)
    response.headers[name].should != nil
    response.headers[name].should == value
  end
  
  should 'send supported version on OPTIONS' do
    response = request(:options, '/')
        
    check_header(response, 'MS-ASProtocolCommands', 'Sync,FolderSync,Ping')
    check_header(response, 'MS-ASProtocolVersions', '12.0, 12.1, 14.0')
    check_header(response, 'MS-Server-ActiveSync', '14.00.0536.000')
    check_header(response, 'Public', 'OPTIONS,POST')
    
    response.status.should == 200
  end
  
  
#   should 'handle FolderCreate' do
#     body = <<-EOS
# <?xml version="1.0" encoding="utf-8"?>
# <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
# <FolderCreate xmlns="FolderHierarchy:">
# <SyncKey>3</SyncKey>
# <ParentId>5</ParentId>
# <DisplayName>MyFolder</DisplayName>
# <Type>12</Type>
# </FolderCreate>
# EOS
    
#     AS::Commands::FolderCreate.any_instance.stubs(:generate_sync_key).returns(22)
#     response = request(:post, '/Microsoft-Server-ActiveSync?Cmd=FolderCreate&User=fakename@Contoso.com&DeviceId=v140Device&DeviceType=SmartPhone',
#         'MS-ASProtocolVersion:' => '14.0',
#         'User-Agent' => 'Dummy',
#         input: body
#       )
    
#     response.status.should == 200
#     response.body.should == <<-EOS 
# <?xml version="1.0" encoding="utf-8"?>
# <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
# <FolderCreate>
#   <Status>1</Status>
#   <SyncKey>22</SyncKey>
#   <ServerId>42</ServerId>
# </FolderCreate>
# EOS
#   end
  
  
end
