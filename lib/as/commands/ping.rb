module AS
  module Commands
    
    class Ping < Command
      STATUS_TIMEOUT             = 1  # heartbeat interval passed with no changes
      STATUS_CHANGED             = 2  # one or more folders changed
      STATUS_INVALID_TIMEOUT     = 5  # timeout is either too big or too low, client will retry with new value
      STATUS_FOLDERSYNC_REQUIRED = 7  # ask the client to issue a FolderSync
      
      MAX_TIMEOUT                = 120
      MIN_TIMEOUT                = 60
      
      # UA known to support timeout change request
      # Unsupported:
      # 'Android/0.3'
      # 
      TIMEOUT_CHANGE_SUPPORTED_UA = [
        'Android/4.0.4-EAS-1.3',      # 4.0.4
        'Android/4.1.1-EAS-1.3'       # 4.1.1
      ]
      
      EAS_WITH_TIMEOUT_CHANGE = [
        'EAS-1.3'
      ].freeze
      
      def support_timeout_change?
        user_agent = @req.user_agent
        if user_agent.start_with?('Android') && user_agent.include?('-EAS')
          eas_version = user_agent.split('-')[1..-1].join('-')
          EAS_WITH_TIMEOUT_CHANGE.include?(eas_version)
        else
          false
        end
      end
      
      def handle!
        timeout = find_text_node(@xml, 'Ping/HeartbeatInterval', :to_f)
        
        body = nil
        
        # don't bother sending back the error, some clients will just ignore it.
        if (timeout > MAX_TIMEOUT) || (timeout < MIN_TIMEOUT)
          if support_timeout_change?
            body = xml do |root|
              root << node('Ping', nil, xmlns: 'Ping:') do |p|
                simple_response(p, STATUS_INVALID_TIMEOUT, (timeout > MAX_TIMEOUT) ? MAX_TIMEOUT : MIN_TIMEOUT)
              end
            end

          else
            timeout = (timeout > MAX_TIMEOUT) ? MAX_TIMEOUT : MIN_TIMEOUT
          end
        end
        
        unless body        
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
        end
        
        @response.status = 200
        @response.body = [Ox.dump(body, with_xml: true)]
      end
    
    private      
      
      def simple_response(p, status, timeout = nil)
        p << node('Status', status)
        
        if timeout
          p << node('HeartbeatInterval', timeout)
        end
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
