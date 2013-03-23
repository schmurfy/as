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
            <WindowSize>40</WindowSize>
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
  end
  
  should 'returns no changes' do
    book = @books[0]
    state = @user.create_savedtstate(book.id)
    @user.update_savedstate(:contacts, state, @user.current_state(book.id))

    
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
  
  should 'honor WindowSize on create' do
    book = @books[0]
    
    book.contacts << build(:contact)
    book.contacts << build(:contact)
    
    book.contacts.size.should == 3
    
    response = as_request('Sync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:">
        <WindowSize>2</WindowSize>
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>0</SyncKey>
            <CollectionId>#{book.id}</CollectionId>
          </Collection>
        </Collections>
      </Sync>
    EOS
    
    @user.contact_states.size.should == 1
    state = @user.contact_states[0]
    
    
    c1 = book.contacts[0]
    c2 = book.contacts[1]
    c3 = book.contacts[2]
    c1_xml = build_contact_xml(c1, 16)
    c2_xml = build_contact_xml(c2, 16)
    c3_xml = build_contact_xml(c3, 16)
    
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
            <MoreAvailable></MoreAvailable>
            <Commands>
              <Add>
                <ServerId>#{c1.id}</ServerId>
                #{c1_xml}
              </Add>
              <Add>
                <ServerId>#{c2.id}</ServerId>
                #{c2_xml}
              </Add>
            </Commands>
          </Collection>
        </Collections>
      </Sync>
    EOS
    
    
    
    
    response = as_request('Sync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:">
        <WindowSize>2</WindowSize>
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>#{state.id}</SyncKey>
            <CollectionId>#{book.id}</CollectionId>
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
            <Commands>
              <Add>
                <ServerId>#{c3.id}</ServerId>
                #{c3_xml}
              </Add>
            </Commands>
          </Collection>
        </Collections>
      </Sync>
    EOS
  end
  
  should 'honor WindowSize on updates' do
    book = @books[0]
    book.contacts << build(:contact)
    book.contacts << build(:contact)
    
    state = @user.create_savedtstate(book.id)
    @user.update_savedstate(:contacts, state, @user.current_state(book.id))
    
    book.contacts.size.should == 3
    
    c1 = book.contacts[0]
    c2 = book.contacts[1]
    c3 = book.contacts[2]
    
    c1.etag = SecureRandom.hex(4)    
    c2.etag = SecureRandom.hex(4)    
    c3.etag = SecureRandom.hex(4)    

    
    response = as_request('Sync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:">
        <WindowSize>2</WindowSize>
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>#{state.id}</SyncKey>
            <CollectionId>#{book.id}</CollectionId>
          </Collection>
        </Collections>
      </Sync>
    EOS
        
    c1_xml = build_contact_xml(c1, 16)
    c2_xml = build_contact_xml(c2, 16)
    c3_xml = build_contact_xml(c3, 16)
    
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
            <MoreAvailable></MoreAvailable>
            <Commands>
              <Change>
                <ServerId>#{c1.id}</ServerId>
                #{c1_xml}
              </Change>
              <Change>
                <ServerId>#{c2.id}</ServerId>
                #{c2_xml}
              </Change>
            </Commands>
          </Collection>
        </Collections>
      </Sync>
    EOS
    
    
    
    
    response = as_request('Sync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:">
        <WindowSize>2</WindowSize>
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>#{state.id}</SyncKey>
            <CollectionId>#{book.id}</CollectionId>
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
            <Commands>
              <Change>
                <ServerId>#{c3.id}</ServerId>
                #{c3_xml}
              </Change>
            </Commands>
          </Collection>
        </Collections>
      </Sync>
    EOS
  end
  
  
  should 'honor WindowSize on delete' do
    book = @books[0]
    book.contacts << build(:contact)
    book.contacts << build(:contact)
    
    state = @user.create_savedtstate(book.id)
    @user.update_savedstate(:contacts, state, @user.current_state(book.id))
    
    book.contacts.size.should == 3
    
    c1 = book.contacts[0]
    c2 = book.contacts[1]
    c3 = book.contacts[2]
    
    book.contacts = []
    
    response = as_request('Sync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:">
        <WindowSize>2</WindowSize>
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>#{state.id}</SyncKey>
            <CollectionId>#{book.id}</CollectionId>
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
            <MoreAvailable></MoreAvailable>
            <Commands>
              <Delete>
                <ServerId>#{c1.id}</ServerId>
              </Delete>
              <Delete>
                <ServerId>#{c2.id}</ServerId>
              </Delete>
            </Commands>
          </Collection>
        </Collections>
      </Sync>
    EOS
    
    
    
    
    response = as_request('Sync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Sync xmlns="AirSync:">
        <WindowSize>2</WindowSize>
        <Collections>
          <Collection>
            <Class>Contacts</Class>
            <SyncKey>#{state.id}</SyncKey>
            <CollectionId>#{book.id}</CollectionId>
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
            <Commands>
              <Delete>
                <ServerId>#{c3.id}</ServerId>
              </Delete>
            </Commands>
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
      
      state = @user.create_savedtstate(@book.id)
      @user.update_savedstate(:contacts, state, @user.current_state(@book.id))
      
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
      
      state = @user.create_savedtstate(@book.id)
      @user.update_savedstate(:contacts, state, @user.current_state(@book.id))
      
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
      
      state = @user.create_savedtstate(@book.id)
      @user.update_savedstate(:contacts, state, @user.current_state(@book.id))
      
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
