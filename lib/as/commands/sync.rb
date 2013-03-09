module AS
  module Commands
    
    class Sync < Command
      
      def handle!
        response_type = :ok
        if savedstate == nil
          @status = STATUS_SYNC_KEY_ERROR
        end
        
        body = xml do |root|
          root << node('Sync', nil, xmlns: "AirSync:") do |fs|
            fs << node('Status', @status)
            
            case @status
            when STATUS_OK  then response_ok(fs)
            end
            
          end
        end
        
        @response.status = 200
        @response.body = [Ox.dump(body, with_xml: true)]
      end
      
    end
    
  end
end
