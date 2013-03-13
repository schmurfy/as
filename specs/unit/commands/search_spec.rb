require File.expand_path('../../../spec_helper', __FILE__)

describe 'Commands::Search' do
  
  before do
    user = @user = Testing::User.new(
        id: 1,
        login: 'john',
        addressbooks: []
      )
    
    serve_app(Rack::Builder.new do
      # use XMLSniffer
      use SpecWithUserMiddleware, user
      run AS::Handler.new
    end)    
  end
  
  should 'return an empty response' do
    response = as_request('FolderSync', <<-EOS)
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Search xmlns="Search:">
        <Store>
          <Name>GAL</Name>
          <Query>some string</Query>
          <Options>
            <Range>0-19</Range>
          </Options>
        </Store>
      </Search>
    EOS
    
    response.status.should == 200
    check_header(response, 'Content-Type', 'application/vnd.ms-sync.wbxml')
    
    response.body.should == unindent(<<-EOS)
      <?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/" >
      <Search xmlns="Search:">
        <Store>
          <Status>1</Status>
          <Result></Result>
        </Store>
      </Search>
    EOS
  end
  
end
