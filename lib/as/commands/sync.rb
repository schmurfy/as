module AS
  module Commands
      
    class Sync < Command
      
      STATUS_SYNC_KEY_ERROR     = 3   # client will try again with a 0 key
      STATUS_CONFLICT           = 7   # client changes overwritten by server (NOTE: the client can open a popup ! )
      STATUS_HIERARCHY_CHANGED  = 12  # the client will send a FolderSync request to refresh
      
      def handle!
        
        # used to store temporary client_id
        @just_created = {}
        
        @windowsize = find_text_node(@xml, 'Sync/WindowSize', :to_i)
        if !@windowsize || (@windowsize == 0)
          # UA: Android/0.3   expects 4 as default
          # specs specify it should be 512
          # @windowsize = 512
          
          @windowsize = 4
        end
        
        # check if the client ent some changes
        @xml.locate('Sync/Collections/Collection').each do |collection|
          collection_id = find_text_node(collection, 'CollectionId')
          sync_key = find_text_node(collection, 'SyncKey')
          changes = collection.locate('Commands/Change')
          added = collection.locate('Commands/Add')
          deleted = collection.locate('Commands/Delete')
          
          # client should not send any changes during initial sync
          # just ignore if they do it anyway.
          if (sync_key != '0')
            state = savedstate(sync_key, collection_id)
            folder = current_user.find_addressbook(collection_id)
            
            unless changes.empty?
              changes.each do |change|
                id = find_text_node(change, 'ServerId')
                data = change.locate('ApplicationData')
                
                # find contact and update it if found
                contact = current_user.find_contact(collection_id, id)
                if contact
                  contact.update_from_xml(data[0])
                  contact.save
                  state.update_contact(folder, contact)
                else
                  raise "unknown contact: #{id}"
                end
              end
            end
            
            unless added.empty?
              added.each do |creation|
                client_id = find_text_node(creation, 'ClientId')
                data = creation.locate('ApplicationData')
                
                contact = current_user.create_contact(collection_id)
                contact.update_from_xml(data[0])
                contact.save
                @just_created[contact.id] = client_id
              end
            end
            
            unless deleted.empty?
              deleted.each do |deletion|
                id = find_text_node(deletion, 'ServerId', :to_i)
                current_user.delete_contact(collection_id, id)
                state.remove_contact(collection_id, id)
              end
            end
            
          end
        end
        
        
        body = xml do |root|
          root << node('Sync', nil, xmlns: "AirSync:") do |fs|
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
          @savedstate ||= current_user.load_savedstate(:contacts, sync_key, folder_id)
        end
      end
      
      def update_saved_state(old_state)
        current_user.update_savedstate(:contacts, old_state)
      end
      
      def collection_error(n, state, folder_id)        
        n << node('Class', @klass)
        n << node('CollectionId', folder_id)
        n << node('Status', @status)
      end
      
      def window_full?(change = 0)
        @windowsize += change
        (@windowsize <= 0)
      end
      
      def collection_ok(n, state, folder)
        n << node('Class', @klass)
        n << node('SyncKey', state.id)
        n << node('CollectionId', folder.id)
        n << node('Status', @status)
        
        created, deleted, updated = state.compare_contacts(folder.id, current_state(folder.id))
        
        if created.size + deleted.size + updated.size > @windowsize
          n << node('MoreAvailable')
        end
        
        responses = node('Responses')
        commands = node('Commands')
        
        created.each do |cached_id, cached_etag|
          contact = folder.find_contact(cached_id)
          unless contact
            raise UnknownContactId
          end
          
          add_node = node('Add') do |a|
            if @just_created[contact.id]
              a << node('ClientId', @just_created[contact.id])
            end
            
            a << node('ServerId', contact.id)
            a << node('ApplicationData'){ |app_data| contact.to_xml(app_data) }
          end
          
          if @just_created[contact.id]
            responses << add_node
          else
            commands << add_node
          end
          
          
          state.add_contact(folder, contact)
          break if window_full?(-1)
        end unless window_full?
        
        updated.each do |cached_id, cached_etag|
          contact = folder.find_contact(cached_id)
          
          commands << node('Change') do |a|
            a << node('ServerId', contact.id)
            a << node('ApplicationData'){ |app_data| contact.to_xml(app_data) }
          end
          
          state.update_contact(folder, contact)
          break if window_full?(-1)
        end unless window_full?
        
        deleted.each do |cached_id, cached_etag|
          commands << node('Delete') do |a|
            a << node('ServerId', cached_id)
          end
          
          state.remove_contact(folder.id, cached_id)
          break if window_full?(-1)
        end unless window_full?
        
        
        n << responses
        n << commands
      end
      
      def do_response(fs)
        collections = @xml.locate('Sync/Collections/Collection')
        collections.each do |c|
          sync_key = find_text_node(c, 'SyncKey')
          folder_id = find_text_node(c, 'CollectionId')
          @klass = find_text_node(c, 'Class') || 'Contacts'
          
          state = savedstate(sync_key, folder_id)
          folder = current_user.find_addressbook(folder_id)
          
          if state == nil
            @status = STATUS_SYNC_KEY_ERROR
          end
          
          if folder == nil
            @status = STATUS_HIERARCHY_CHANGED
          end
          
          fs << node('Collection') do |n|
            if @status == STATUS_OK
              begin
                collection_ok(n, state, folder)
                update_saved_state(state)
              rescue UnknownFolderId
                @status = STATUS_HIERARCHY_CHANGED
                collection_error(n, state, folder_id)
              end
            else
              collection_error(n, state, folder_id)
            end
          end
          
        end
          
      end
      
      
      
      
    end
    
  end
end
