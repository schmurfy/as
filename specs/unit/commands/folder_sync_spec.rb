require File.expand_path('../../../spec_helper', __FILE__)

describe 'Commands::FolderSync' do
  before do
    @books = []
    @books << Testing::AddressBook.new(
        id: 34,
        etag: 'b34',
        displayname: 'a book'
      )
    
    user = @user = Testing::User.new(
        id: 1,
        login: 'john',
        addressbooks: @books
      )

    serve_app(Rack::Builder.new do
      # use XMLSniffer
      use SpecWithUserMiddleware, user
      run AS::Handler.new
    end)    
  end
  
  
  should 'handle initial request and return all folders' do
    
    response = as_request('FolderSync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <FolderSync xmlns="FolderHierarchy:">
        <SyncKey>0</SyncKey>
      </FolderSync>
    EOS
    
    response.status.should == 200
    check_header(response, 'Content-Type', 'application/vnd.ms-sync.wbxml')
    
    # a new state should be create and its id returned to the client
    @user.folder_states.size.should == 1
    state = @user.folder_states[0]
    
    response.body.should == unindent(<<-EOS)
      <?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <FolderSync xmlns="FolderHierarchy:">
        <Status>1</Status>
        <SyncKey>#{state.id}</SyncKey>
        <Changes>
          <Count>1</Count>
          <Add>
            <ServerId>#{@books[0].id}</ServerId>
            <ParentId>0</ParentId>
            <DisplayName>#{@books[0].displayname}</DisplayName>
            <Type>#{AS::Command::FOLDER_TYPE_CONTACTS_DEFAULT}</Type>
          </Add>
        </Changes>
      </FolderSync>
    EOS
    
    # should return an empty response
    response = as_request('FolderSync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <FolderSync xmlns="FolderHierarchy:">
        <SyncKey>#{state.id}</SyncKey>
      </FolderSync>
    EOS
    
    response.status.should == 200
    response.body.should == unindent(<<-EOS)
      <?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <FolderSync xmlns="FolderHierarchy:">
        <Status>1</Status>
        <SyncKey>#{state.id}</SyncKey>
        <Changes/>
      </FolderSync>
    EOS
    
  end
  
  
  should 'return an error for an invalid sync key' do
    
    response = as_request('FolderSync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <FolderSync xmlns="FolderHierarchy:">
        <SyncKey>k23</SyncKey>
      </FolderSync>
    EOS
    
    response.status.should == 200
    check_header(response, 'Content-Type', 'application/vnd.ms-sync.wbxml')
    
    # a new state should be create and its id returned to the client
    @user.folder_states.size.should == 0
        
    response.body.should == unindent(<<-EOS)
      <?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <FolderSync xmlns="FolderHierarchy:">
        <Status>#{AS::Commands::FolderSync::STATUS_SYNC_KEY_ERROR}</Status>
      </FolderSync>
    EOS
  end
  
end
