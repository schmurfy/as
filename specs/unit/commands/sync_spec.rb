require File.expand_path('../../../spec_helper', __FILE__)

describe 'Commands::Sync' do
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
  
  
  should 'handle Sync' do
    
    response = as_request('Sync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:">
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>0</SyncKey>
            <CollectionId>42</CollectionId>
          </Collection>
        </Collections>
      </Sync>
    EOS
    
    response.status.should == 200
    response.body.should == unindent(<<-EOS )
      <?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE ActMMMiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <FolderCreate>
        <Status>1</Status>
        <SyncKey>3</SyncKey>
        <ServerId>42</ServerId>
      </FolderCreate>
    EOS
  end
  
end
