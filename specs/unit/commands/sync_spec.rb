require File.expand_path('../../../spec_helper', __FILE__)

describe 'Commands::Sync' do
  before do
    @books = []
    @books << Testing::AddressBook.new(
        id: 34,
        etag: 'b34',
        displayname: 'a book',
        contacts: [
          build(:contact)
        ]
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
    book = @books[0]
    
    response = as_request('Sync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:">
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>0</SyncKey>
            <CollectionId>#{book.id}</CollectionId>
            <WindowSize>4</WindowSize>
          </Collection>
        </Collections>
      </Sync>
    EOS
    
    @user.contact_states.size.should == 1
    state = @user.contact_states[0]
    
    
    c = book.contacts[0]
    
    response.status.should == 200
    response.body.should == unindent(<<-EOS )
      <?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:" xmlns:C="Contacts:">
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>#{state.id}</SyncKey>
            <CollectionId>#{book.id}</CollectionId>
            <Status>1</Status>
            <Commands>
              <Add>
                <ServerId>#{c.id}</ServerId>
                <ApplicationData>
                  <C:FileAs>#{c.fileas}</C:FileAs>
                  <C:FirstName>#{c.firstname}</C:FirstName>
                  <C:LastName>#{c.lastname}</C:LastName>
                  <C:CompanyName>#{c.company_name}</C:CompanyName>
                </ApplicationData>
              </Add>
            </Commands>
          </Collection>
        </Collections>
      </Sync>
    EOS
    
    
    # another request should return nothing
    response = as_request('Sync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:">
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>#{state.id}</SyncKey>
            <CollectionId>#{book.id}</CollectionId>
            <WindowSize>4</WindowSize>
          </Collection>
        </Collections>
      </Sync>
    EOS
    
    response.status.should == 200
    response.body.should == unindent(<<-EOS )
      <?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:" xmlns:C="Contacts:">
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>#{state.id}</SyncKey>
            <CollectionId>#{book.id}</CollectionId>
            <Status>1</Status>
            <Commands/>
          </Collection>
        </Collections>
      </Sync>
    EOS
    
    
  end
  
end
