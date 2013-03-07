require 'ox'

module AS
    
  class Handler
    def call(env)
      req = Rack::Request.new(env)
      
      m = req.request_method.downcase
      
      if respond_to?(m)
        Rack::Response.new.tap do |response|
          response.status = 404
          
          send(m, req, response)
        end
      else
        [404, {}, ['unsupported']]
      end
    end
    
    def options(req, response)
      response.status = 200
      
      response.header['MS-ASProtocolVersions'] = '12.0, 12.1, 14.0'
      response.header['MS-ASProtocolCommands'] = 'Sync'
      response.header['MS-Server-ActiveSync'] = '14.00.0536.000'
      response.header['Public'] = 'OPTIONS,POST'
    end
    
    def post(req, response)
      response.header['Content-Type'] = 'application/vnd.ms-sync.wbxml'
      
      r = Ox.parse(req.body.read)
      
      case r.nodes[0].value
      when "FolderSync"
        key = r.locate('FolderSync/SyncKey/?[0]').first
        folder_sync(key, response)
      
      when 'FolderCreate'
        key = r.locate('FolderCreate/SyncKey/?[0]').first
        parent_id = r.locate('FolderCreate/ParentId/?[0]').first
        display_name = r.locate('FolderCreate/DisplayName/?[0]').first
        
        folder_create(key, parent_id, display_name, response)
        
      end
      
    end
    
  private
    def xml()
      Ox::Document.new(version: '1.0', encoding: 'utf-8').tap do |x|
        yield(x)
      end
    end
    
    def node(name, text = nil)
      Ox::Element.new(name).tap do |n|
        if block_given?
          yield(n)
        else
          n << text
        end
      end
    end
    
    
    
    def folder_sync(key, response)
      status = "1"
      changes = []
      
      body = xml do |root|
        root << node('FolderSync') do |fs|
          fs << node('Status', status)
          fs << node('SyncKey', key)
          fs << node('Changes') do |c|
            c << node('Count', changes.size.to_s)
          end
        end
      end
      
      response.status = 200
      response.body = [Ox.dump(body, with_xml: true)]
    end
    
    
    def folder_create(key, parent_id, display_name, response)
      status = '1'
      id = '42'
      
      body = xml do |root|
        root << node('FolderCreate') do |x|
          x << node('Status', status)
          x << node('SyncKey', key)
          x << node('ServerId', id)
        end
      end
      
      response.status = 200
      response.body = [Ox.dump(body, with_xml: true)]
    end
    
  end
  
end
