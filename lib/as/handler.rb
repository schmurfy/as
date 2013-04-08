require 'ox'

module AS
  
  FOLDER_NS = "FolderHierarchy:"
  AIRSYNC_NS = "AirSync:"
  
  class DummyLogger
    def log(*)
      
    end
    
    def with_context(*)
      yield
    end
  end
  
  class Handler
    def initialize(opts = {})
      @current_user = opts.delete(:current_user)
      @logger = opts.delete(:logger) || DummyLogger.new
      raise "unknown options: #{opts}" unless opts.empty?
    end
    
    def call(env)
      req = Rack::Request.new(env)
      
      m = req.request_method.downcase
      
      if respond_to?(m)
        response = Rack::Response.new
        response.status = 404 
        add_common_headers!(response)
        send(m, req, response)
        
        if response.body[0]
          response.headers['Content-Length'] = response.body[0].size
        end
        
        response.finish
      else
        [404, {}, ['unsupported']]
      end
      
    rescue => err
      p err
      puts err.backtrace.each.to_a.join("\n")
    end
    
    def options(req, response)
      response.status = 200
      
      # response.header['MS-ASProtocolVersions'] = '1.0,2.0,2.1,2.5'
      response.header['MS-ASProtocolVersions'] = '12.0,12.1,14.0'
      # response.header['MS-ASProtocolCommands'] = 'Sync,SendMail,SmartForward,SmartReply,GetAttachment,GetHierarchy,CreateCollection,DeleteCollection,MoveCollection,FolderSync,FolderCreate,FolderDelete,FolderUpdate,MoveItems,GetItemEstimate,MeetingResponse,ResolveRecipients,ValidateCert,Provision,Search,Ping,Notify'
      response.header['MS-ASProtocolCommands'] = 'Sync,FolderSync,Ping'
      response.header['Public'] = 'OPTIONS,POST'
    end
    
    def post(req, response)
      response.header['Content-Type'] = 'application/vnd.ms-sync.wbxml'
      
      data = req.body.read
      r = Ox.load(data.force_encoding('utf-8'))
      if r
        cmd = nil
        
        case r.nodes[1].value
        when "FolderSync"   then cmd = Commands::FolderSync
        when "Sync"         then cmd = Commands::Sync
        when "Ping"         then cmd = Commands::Ping
        when "Search"       then cmd = Commands::Search
        end
        
        
        if cmd
          @logger.with_context(cmd: cmd) do
            cmd.new(r, req, response, @current_user, @logger).handle!
          end
          
          @logger.log("Request completed.")
        end
      else
        p [:parse_error, data]
      end
    end
    
  private
    def add_common_headers!(response)
      # response.header['MS-Server-ActiveSync'] = '6.5.7638.1'
      response.header['MS-Server-ActiveSync'] = '14.00.0536.000'

    end
    
  end
  
end
