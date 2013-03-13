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
      def sync_key
        @sync_key ||= @xml.locate('*/SyncKey/?[0]').first
      end
      
      def update_saved_state(key, new_state)
        current_user.update_savedstate(:folders, key, new_state)
      end

      
      def savedstate
        if sync_key == '0'
          @savedstate ||= current_user.create_savedtstate(nil)
        else
          @savedstate ||= current_user.load_savedstate(:folders, sync_key)
        end
      end

      
      def response_ok(fs)
        state = savedstate()
        
        created, deleted, updated = state.compare_folders(current_state())
        update_saved_state(state.id, current_state())
        
        fs << node('SyncKey', state.id )
        fs << node('Changes') do |c|
          changes_count = created.size + deleted.size + updated.size
          c << node('Count', changes_count) if changes_count > 0
          
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
