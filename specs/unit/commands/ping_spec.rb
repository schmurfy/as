require File.expand_path('../../../spec_helper', __FILE__)

describe 'Commands::Ping' do
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
  
  
  should 'handle ping' do
    
    response = as_request('Ping', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Ping xmlns="Ping:">
        <HeartbeatInterval>2</HeartbeatInterval>
        <Folders>
          <Folder>
            <Id>34</Id>
            <Class>Contacts</Class>
          </Folder>
        </Folders>
      </Ping>
    EOS
    
    response.status.should == 200
    check_header(response, 'Content-Type', 'application/vnd.ms-sync.wbxml')
    
    # a new state should be create and its id returned to the client
    @user.folder_states.size.should == 0
        
    response.body.should == unindent(<<-EOS)
      <?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Ping xmlns="Ping:">
        <Status>1</Status>
      </Ping>
    EOS
  end
  
  
  # should 'send back changes' do    
    
  #   response.body.should == unindent(<<-EOS)
  #     <?xml version="1.0" encoding="utf-8"?>
  #     <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
  #     <Ping xmlns="Ping:">
  #       <Status>1</Status>
  #       <Folders>
  #         <Folder>34</Folder>
  #       </Folders>
  #     </Ping>
  #   EOS
  # end
  
end
