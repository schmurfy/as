module AS
  module Commands
    
    class FolderSync < Command
      STATUS_SERVER_ERROR     = 6   # server error, client wil retry
      STATUS_SYNC_KEY_ERROR   = 9   # client will try again with a 0 key
      STATUS_INVALID_REQUEST  = 10  # client sent a malformed request
      STATUS_UNKNOWN_ERROR    = 11  # server error, client will retry
      
      def handle!
        response_type = :ok
        if savedstate == nil
          @status = STATUS_SYNC_KEY_ERROR
        end
        
        body = xml do |root|
          root << node('FolderSync', nil, xmlns: "FolderHierarchy:") do |fs|
            fs << node('Status', @status)
            
            case @status
            when STATUS_OK  then response_ok(fs)
            end
            
          end
        end
        
        @response.status = 200
        @response.body = [Ox.dump(body, with_xml: true)]
      end
    
    
    private
      def response_ok(fs)
        created, deleted, updated = savedstate.compare_folders(current_user.current_state)
        
        fs << node('SyncKey', savedstate.id )
        fs << node('Changes') do |c|
          c << node('Count', created.size + deleted.size + updated.size )
          
          created.each.with_index do |cached_folder, i|
            folder = current_user.find_addressbook(cached_folder.id)
            c << node('Add') do |a|
              a << node('ServerId', folder.id)
              a << node('ParentId', '0')
              a << node('DisplayName', folder.displayname)
              a << node('Type', FOLDER_TYPE_CONTACTS_DEFAULT)
            end
          end
          
          updated.each.with_index do |cached_folder, i|
            folder = current_user.find_addressbook(cached_folder.id)
            c << node('Update') do |a|
              a << node('ServerId', folder.id)
              a << node('ParentId', '0')
              a << node('DisplayName', folder.displayname)
              a << node('Type', FOLDER_TYPE_CONTACTS)
            end
          end

          
          deleted.each do |cached_folder|
            c << node('Delete') do |d|
              d << node('ServerId', cached_folder.id)
            end
          end
          
        end
      end
                  
    end
    
    
  end
end
