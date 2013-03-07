require 'base64'

module AS
  
  class Request
    attr_accessor :user
    attr_accessor :device_id
    attr_accessor :device_type
    attr_accessor :params
    
    
    def self.load_from_rack(env)
      query_params = Rack::Utils.parse_query(env['QUERY_STRING'])
      ret = nil
      
      unless query_params['Cmd']
        data = Base64.decode64(query_params.keys[0])
        p data
      end
      
      case query_params.delete('Cmd')
      when 'Sync'       then ret = SyncRequest.new
      # when 'FolderSync' then
      # when 'FolderCreate' then
      # when 'FolderDelete' then
      # when 'FolderUpdate' then
      # when 'MoveItems' then
      # when 'GetItemEstimate' then
      # when 'Search' then
      # when 'Ping' then
      # when 'Provision' then
      else
        raise 'unsupported'
      end
      
      ret.user = query_params.delete('User')
      ret.device_id = query_params.delete('DeviceId')
      ret.device_type = query_params.delete('DeviceType')
      
      # emaining parameters
      ret.params = query_params
      
      ret
    end
    
    
  end
  
  
  class SyncRequest < Request
    
  end
  
end
