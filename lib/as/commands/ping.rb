module AS
  module Commands
    
    class Ping < Command
      STATUS_TIMEOUT             = 1  # heartbeat interval passed with no changes
      STATUS_CHANGED             = 2  # one or more folders changed
      STATUS_FOLDERSYNC_REQUIRED = 7  # ask the client to issue a FolderSync
      
      def handle!
        timeout = find_text_node(@xml, 'Ping/HeartbeatInterval')
        
        folder_ids = []
        
        folders = @xml.locate('Ping/Folders/Folder')
        folders.each do |folder|
          id    = find_text_node(folder, 'Id')
          klass = find_text_node(folder, 'Class')
          folder_ids << id
        end
        
        @logger.log("[Ping] Waiting for changes on #{folder_ids} for #{timeout}s")
        
        changed = Watcher.instance.wait_for_changes(current_user.id, folder_ids, timeout)
        
        body = xml do |root|
          root << node('Ping', nil, xmlns: 'Ping:') do |p|
            if changed == :resync
              @logger.log("[Ping] Resumed, resync required")
              simple_response(p, STATUS_FOLDERSYNC_REQUIRED)
            elsif changed.empty?
              @logger.log("[Ping] Resumed after timeout")
              simple_response(p, STATUS_TIMEOUT)
            else
              @logger.log("[Ping] Resumed with #{changed.size} changes")
              changes_response(p, changed)
            end
          end
        end
        
        @response.status = 200
        @response.body = [Ox.dump(body, with_xml: true)]
      end
    
    private
      def simple_response(p, status)
        p << node('Status', status)
      end
      
      def changes_response(p, changed)
        p << node('Status', STATUS_CHANGED)
        p << node('Folders') do |folders|
          changed.each do |id|
            folders << node('Folder', id)
          end
        end
      end
      
    end
    
  end
end
