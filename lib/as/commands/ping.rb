module AS
  module Commands
    
    class Ping < Command
      STATUS_TIMEOUT = 1  # heartbeat interval passed with no changes
      STATUS_CHANGED = 2  # one or more folders changed
      
      def handle!
        timeout = find_text_node(@xml, 'Ping/HeartbeatInterval')
        
        suspend(timeout)
        
        body = xml do |root|
          root << node('Ping', nil, xmlns: 'Ping:') do |p|
            timeout_response(p)
          end
        end
        
        @response.status = 200
        @response.body = [Ox.dump(body, with_xml: true)]
      end
    
    private
      def timeout_response(p)
        p << node('Status', STATUS_TIMEOUT)
      end
      
      
      def changes_response()
        p << node('Status', STATUS_CHANGED)
      end
      
    end
    
  end
end
