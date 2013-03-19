require File.expand_path('../../../spec_helper', __FILE__)

require 'active_support/core_ext'

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
  
  
  describe 'with overriden timeout' do
    before do
      @old_timeout = AS::Commands::Ping::MIN_TIMEOUT
      
      silence_warnings do
        AS::Commands::Ping::MIN_TIMEOUT = 1
      end
    end
    
    after do
      silence_warnings do
        AS::Commands::Ping::MIN_TIMEOUT = @old_timeout
      end
    end
  
    should 'handle ping without changes' do
      started_at = Time.now
      response = as_request('Ping', <<-EOS)
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Ping xmlns="Ping:">
          <HeartbeatInterval>1</HeartbeatInterval>
          <Folders>
            <Folder>
              <Id>34</Id>
              <Class>Contacts</Class>
            </Folder>
          </Folders>
        </Ping>
      EOS
      
      response.status.should == 200
      (Time.now - started_at).should.be.close?(1.0, 0.1)
      check_header(response, 'Content-Type', 'application/vnd.ms-sync.wbxml')
      
      # no state should be created
      @user.folder_states.size.should == 0
          
      response.body.should == unindent(<<-EOS)
        <?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Ping xmlns="Ping:">
          <Status>#{AS::Commands::Ping::STATUS_TIMEOUT}</Status>
        </Ping>
      EOS
    end
    
    
    should 'send back changes' do
      started_at = Time.now
      
      EM::add_timer(0.5) do
        AS::Watcher.instance.trigger_change('34')
      end
      
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
      (Time.now - started_at).should.be.close?(0.5, 0.05)
      check_header(response, 'Content-Type', 'application/vnd.ms-sync.wbxml')
      
      # no state should be created
      @user.folder_states.size.should == 0
          
      response.body.should == unindent(<<-EOS)
        <?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Ping xmlns="Ping:">
          <Status>#{AS::Commands::Ping::STATUS_CHANGED}</Status>
          <Folders>
            <Folder>34</Folder>
          </Folders>
        </Ping>
      EOS
    end
    
    
    should 'trigger a resync' do
      started_at = Time.now
      
      EM::add_timer(0.6) do
        AS::Watcher.instance.trigger_resync(@user.id)
      end
      
      response = as_request('Ping', <<-EOS)
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Ping xmlns="Ping:">
          <HeartbeatInterval>3</HeartbeatInterval>
          <Folders>
            <Folder>
              <Id>34</Id>
              <Class>Contacts</Class>
            </Folder>
          </Folders>
        </Ping>
      EOS
      
      response.status.should == 200
      (Time.now - started_at).should.be.close?(0.6, 0.07)
      check_header(response, 'Content-Type', 'application/vnd.ms-sync.wbxml')
      
      # no state should be created
      @user.folder_states.size.should == 0
          
      response.body.should == unindent(<<-EOS)
        <?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Ping xmlns="Ping:">
          <Status>#{AS::Commands::Ping::STATUS_FOLDERSYNC_REQUIRED}</Status>
        </Ping>
      EOS
    end
    
  end
  
  # TODO
  # describe 'For devices without timeout change support' do
    # should 'force the timeout without asking' do
    #   response = as_request('Ping', <<-EOS)
    #     <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
    #     <Ping xmlns="Ping:">
    #       <HeartbeatInterval>2000</HeartbeatInterval>
    #       <Folders>
    #         <Folder>
    #           <Id>34</Id>
    #           <Class>Contacts</Class>
    #         </Folder>
    #       </Folders>
    #     </Ping>
    #   EOS

    # end

  # end
    
  
  describe 'For devices supporting timeout change' do    
    should 'answer with supported timeout if too high' do
      response = as_request('Ping', <<-EOS, user_agent: 'Android/4.1.1-EAS-1.3')
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Ping xmlns="Ping:">
          <HeartbeatInterval>2000</HeartbeatInterval>
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

      
      response.body.should == unindent(<<-EOS)
        <?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Ping xmlns="Ping:">
          <Status>#{AS::Commands::Ping::STATUS_INVALID_TIMEOUT}</Status>
          <HeartbeatInterval>#{AS::Commands::Ping::MAX_TIMEOUT}</HeartbeatInterval>
        </Ping>
      EOS
    end
    
    should 'answer with supported timeout if too low' do
      response = as_request('Ping', <<-EOS, user_agent: 'Android/4.1.1-EAS-1.3')
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Ping xmlns="Ping:">
          <HeartbeatInterval>1</HeartbeatInterval>
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

      
      response.body.should == unindent(<<-EOS)
        <?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
        <Ping xmlns="Ping:">
          <Status>#{AS::Commands::Ping::STATUS_INVALID_TIMEOUT}</Status>
          <HeartbeatInterval>#{AS::Commands::Ping::MIN_TIMEOUT}</HeartbeatInterval>
        </Ping>
      EOS
    end
  end

  
end
