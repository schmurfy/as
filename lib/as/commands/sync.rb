module AS
  module Commands
      
    class Sync < Command
      
      STATUS_SYNC_KEY_ERROR   = 3   # client will try again with a 0 key
      
      def handle!
        
        body = xml do |root|
          root << node('Sync', nil, xmlns: "AirSync:", "xmlns:C" => 'Contacts:') do |fs|
            fs << node('Collections') do |collections|
              do_response(collections)
            end
          end
        end
        
        @response.status = 200
        @response.body = [Ox.dump(body, with_xml: true)]
      end
    
    private
      def savedstate(sync_key, folder_id)
        if sync_key == '0'
          @savedstate ||= current_user.create_savedtstate(folder_id)
        else
          @savedstate ||= current_user.load_savedstate(:contacts, sync_key)
        end
      end
      
      def update_saved_state(sync_key, new_state)
        current_user.update_savedstate(:contacts, sync_key, new_state)
      end
      
      def collection_error(n, state, folder_id)        
        n << node('Class', @klass)
        n << node('CollectionId', folder_id)
        n << node('Status', @status)
      end
      
      
      def collection_ok(n, state, folder_id)
        n << node('Class', @klass)
        n << node('SyncKey', state.id)
        n << node('CollectionId', folder_id)
        n << node('Status', @status)
        
        created, deleted, updated = state.compare_contacts(folder_id, current_state())
        
        
        n << node('Commands') do |cmds|
          created.each do |cached_contact|
            contact = current_user.find_contact(folder_id, cached_contact.id)
            cmds << node('Add') do |a|
              a << node('ServerId', contact.id)
              a << node('ApplicationData'){ |app_data| contact.to_xml(app_data) }
            end
          end
          
          updated.each do |cached_contact|
            contact = current_user.find_contact(folder_id, cached_contact.id)
            cmds << node('Change') do |a|
              a << node('ServerId', contact.id)
              a << node('ApplicationData') do |app_data|
                app_data << node('FileAs', contact.fileas, xmlns: 'Contacts:')
                app_data << node('FirstName', contact.firstname, xmlns: 'Contacts:')
                app_data << node('LastName', contact.lastname, xmlns: 'Contacts:')
              end
            end
          end
          
          deleted.each do |cached_contact|
            cmds << node('Delete') do |a|
              a << node('ServerId', cached_contact.id)
            end
          end
          
        end
      end
      
      def do_response(fs)
        collections = @xml.locate('Sync/Collections/Collection')
        collections.each do |c|
          sync_key = find_text_node(c, 'SyncKey')
          folder_id = find_text_node(c, 'CollectionId')
          @klass = find_text_node(c, 'Class') || 'Contacts'
          
          state = savedstate(sync_key, folder_id)
          
          if state == nil
            @status = STATUS_SYNC_KEY_ERROR
          end
          
          fs << node('Collection') do |n|
            if @status == STATUS_OK
              collection_ok(n, state, folder_id)
              update_saved_state(state.id, current_state())
            else
              collection_error(n, state, folder_id)
            end
          end
          
        end
          
      end
      
      
      
      
    end
    
  end
end
