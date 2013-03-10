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
      
      def response_ok(fs)
        collections = @xml.locate('Sync/Collections/Collection')
        collections.each do |c|
          klass = find_text_node(c, 'Class')
          p klass
        end
        
        # window_size = @xml.locate('*/Collection/WindowSize/?[0]').first.to_i
      end
      
    end
    
  end
end
