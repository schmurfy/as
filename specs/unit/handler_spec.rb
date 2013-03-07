require File.expand_path('../../spec_helper', __FILE__)


describe 'Handler' do
  before do
    app = Rack::Builder.new do
      # use XMLSniffer
      run AS::Handler.new
    end
    
    serve_app(app)
  end
  
  should 'send supported version on OPTIONS' do
    response = request(:options, '/')
    
    response.headers['MS-ASProtocolCommands'].should != nil
    response.headers['MS-ASProtocolCommands'].should == "Sync"
    
    response.headers['MS-ASProtocolVersions'].should != nil
    response.headers['MS-ASProtocolVersions'].should == "12.0, 12.1, 14.0"
    
    response.headers['MS-Server-ActiveSync'].should != nil
    response.headers['MS-Server-ActiveSync'].should == "14.00.0536.000"
    
    response.headers['Public'].should != nil
    response.headers['Public'].should == "OPTIONS,POST"
    
    response.status.should == 200
  end
  
  
  # POST /Microsoft-Server-ActiveSync?Cmd=FolderSync&User=fakename&DeviceId=v140Device&DeviceType=SmartPhone HTTP/1.1
  # Content-Type: application/vnd.ms-sync.wbxml
  # MS-ASProtocolVersion: 14.0
  # User-Agent: ASOM
  # Host: Contoso.com
  # <?xml version="1.0" encoding="utf-8"?> <FolderSync xmlns="FolderHierarchy:">
  #   <SyncKey>2</SyncKey>
  # </FolderSync>
  should 'handle FolderSync request' do
    body = <<-EOS    
<?xml version="1.0" encoding="utf-8"?>
<FolderSync xmlns="FolderHierarchy:">
  <SyncKey>2</SyncKey>
</FolderSync>
EOS
    response = request(:post, '/Microsoft-Server-ActiveSync?Cmd=FolderSync&User=fakename&DeviceId=v140Device&DeviceType=SmartPhone',
        'MS-ASProtocolVersion:' => '14.0',
        'User-Agent' => 'Dummy',
        input: body
      )
    
    response.status.should == 200
    response.headers['Content-Type'].should == 'application/vnd.ms-sync.wbxml'
    response.body.should == <<-EOS 
<?xml version="1.0" encoding="utf-8"?>
<FolderSync>
  <Status>1</Status>
  <SyncKey>2</SyncKey>
  <Changes>
    <Count>0</Count>
  </Changes>
</FolderSync>
EOS
  end
  
  
  
  
  should 'handle FolderCreate' do
    body = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<FolderCreate xmlns="FolderHierarchy:">
<SyncKey>3</SyncKey>
<ParentId>5</ParentId>
<DisplayName>MyFolder</DisplayName>
<Type>12</Type>
</FolderCreate>
EOS

    response = request(:post, '/Microsoft-Server-ActiveSync?Cmd=FolderCreate&User=fakename@Contoso.com&DeviceId=v140Device&DeviceType=SmartPhone',
        'MS-ASProtocolVersion:' => '14.0',
        'User-Agent' => 'Dummy',
        input: body
      )
    
    response.status.should == 200
    response.body.should == <<-EOS 
<?xml version="1.0" encoding="utf-8"?>
<FolderCreate>
  <Status>1</Status>
  <SyncKey>3</SyncKey>
  <ServerId>42</ServerId>
</FolderCreate>
EOS
  end
  
  
end
