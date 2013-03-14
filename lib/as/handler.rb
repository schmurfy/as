require 'ox'

module AS
  
  FOLDER_NS = "FolderHierarchy:"
  AIRSYNC_NS = "AirSync:"
  
  
  
  class Handler
    def initialize(opts = {})
      @current_user = opts.delete(:current_user) || raise("current_user required")
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
      
      r = Ox.parse(req.body.read)
      cmd = nil
      
      case r.nodes[1].value
      when "FolderSync"   then cmd = Commands::FolderSync
      when "Sync"         then cmd = Commands::Sync
      when "Ping"         then cmd = Commands::Ping
      when "Search"       then cmd = Commands::Search
      
      when 'FolderCreate'
        key = r.locate('*/SyncKey/?[0]').first
        parent_id = r.locate('FolderCreate/ParentId/?[0]').first
        display_name = r.locate('FolderCreate/DisplayName/?[0]').first
        
        folder_create(key, parent_id, display_name, response)
        
      end
      
      
      if cmd
        cmd.new(r, req, response, @current_user).handle!
      end
      
    end
    
  private
    def add_common_headers!(response)
      # response.header['MS-Server-ActiveSync'] = '6.5.7638.1'
      response.header['MS-Server-ActiveSync'] = '14.00.0536.000'

    end
    
  end
  
end
