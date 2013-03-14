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
    contact_xml = build_contact_xml(c, 16)
    
    response.status.should == 200
    response.body.should == unindent(<<-EOS )
      <?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:">
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>#{state.id}</SyncKey>
            <CollectionId>#{book.id}</CollectionId>
            <Status>1</Status>
            <Commands>
              <Add>
                <ServerId>#{c.id}</ServerId>
                #{contact_xml}
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
      <Sync xmlns="AirSync:">
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
  
  
  describe 'Client update' do
    
    before do
      @book = @books[0]
    end
    
    after do
      @user.contact_states.size.should == 1
    end
    
    
    should 'handle creation' do
      contact = @book.contacts[0]
      
      state = @user.current_state()
      @user.update_savedstate(:contacts, state.id, state)
      
      response = as_request('Sync', <<-EOS)
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Sync xmlns="AirSync:">
          <Collections>
            <Collection>
              <Class>Contacts</Class>
              <SyncKey>#{state.id}</SyncKey>
              <CollectionId>#{@book.id}</CollectionId>
              <WindowSize>4</WindowSize>
              <Commands>
                <Add>
                  <ClientId>some_random_crap</ClientId>
                  <ApplicationData>
                    <LastName xmlns="Contacts:">D</LastName>
                    <FirstName xmlns="Contacts:">Z</FirstName>
                    <FileAs xmlns="Contacts:">Z D</FileAs>
                  </ApplicationData>
                </Add>
              </Commands>
            </Collection>
          </Collections>
        </Sync>
      EOS
      
      @book.contacts.size.should == 2
      
      new_contact = @book.contacts[1]
      new_contact_xml = build_contact_xml(new_contact, 18)
      
      response.status.should == 200
      response.body.should == unindent(<<-EOS )
        <?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Sync xmlns="AirSync:">
          <Collections>
            <Collection>
              <Class>Contacts</Class>
              <SyncKey>#{state.id}</SyncKey>
              <CollectionId>#{@book.id}</CollectionId>
              <Status>1</Status>
              <Commands>
                <Add>
                  <ServerId>#{new_contact.id}</ServerId>
                  <ClientId>some_random_crap</ClientId>
                  #{new_contact_xml}
                </Add>
              </Commands>
            </Collection>
          </Collections>
        </Sync>
      EOS
      
    end
    
    
    should 'handle change' do
      contact = @book.contacts[0]
      
      state = @user.current_state()
      @user.update_savedstate(:contacts, state.id, state)
      
      response = as_request('Sync', <<-EOS)
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Sync xmlns="AirSync:">
          <Collections>
            <Collection>
              <Class>Contacts</Class>
              <SyncKey>#{state.id}</SyncKey>
              <CollectionId>#{@book.id}</CollectionId>
              <WindowSize>4</WindowSize>
              <Commands>
                <Change>
                  <ServerId>#{contact.id}</ServerId>
                  <ApplicationData>
                    <LastName xmlns="Contacts:">#{contact.lastname}</LastName>
                    <FirstName xmlns="Contacts:">Jacques</FirstName>
                    <YomiFirstName xmlns="Contacts:"/>
                    <YomiLastName xmlns="Contacts:"/>
                    <Title xmlns="Contacts:"/>
                    <FileAs xmlns="Contacts:">Jacques #{contact.lastname}</FileAs>
                    <HomePhoneNumber xmlns="Contacts:">1113</HomePhoneNumber>
                  </ApplicationData>
                </Change>
              </Commands>
            </Collection>
          </Collections>
        </Sync>
      EOS
      
      response.status.should == 200
      changed_contact_xml = build_contact_xml(contact, 18)
      response.body.should == unindent(<<-EOS )
        <?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Sync xmlns="AirSync:">
          <Collections>
            <Collection>
              <Class>Contacts</Class>
              <SyncKey>#{state.id}</SyncKey>
              <CollectionId>#{@book.id}</CollectionId>
              <Status>1</Status>
              <Commands>
                <Change>
                  <ServerId>#{contact.id}</ServerId>
                  #{changed_contact_xml}
                </Change>
              </Commands>
            </Collection>
          </Collections>
        </Sync>
      EOS
      
      contact.firstname.should == 'Jacques'
    end
    
    
    should 'handle deletion' do
      contact = @book.contacts[0]
      
      state = @user.current_state()
      @user.update_savedstate(:contacts, state.id, state)
      
      response = as_request('Sync', <<-EOS)
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Sync xmlns="AirSync:">
          <Collections>
            <Collection>
              <Class>Contacts</Class>
              <SyncKey>#{state.id}</SyncKey>
              <CollectionId>#{@book.id}</CollectionId>
              <WindowSize>4</WindowSize>
              <Commands>
                <Delete>
                  <ServerId>#{contact.id}</ServerId>
                </Delete>
              </Commands>
            </Collection>
          </Collections>
        </Sync>
      EOS
      
      response.status.should == 200
      @book.contacts.size.should == 0
      
      response.body.should == unindent(<<-EOS )
        <?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Sync xmlns="AirSync:">
          <Collections>
            <Collection>
              <Class>Contacts</Class>
              <SyncKey>#{state.id}</SyncKey>
              <CollectionId>#{@book.id}</CollectionId>
              <Status>1</Status>
              <Commands>
                <Delete>
                  <ServerId>#{contact.id}</ServerId>
                </Delete>
              </Commands>
            </Collection>
          </Collections>
        </Sync>
      EOS
      
    end
    
  end
  
end
