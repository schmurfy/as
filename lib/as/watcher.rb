require 'singleton'

module AS
  
  #
  # provide basic mechanism to watch and be notified of changes
  # 
  class Watcher
    include Singleton
    
    def initialize
      reset()
    end
    
    def reset
      @watchers = {}
      @watching_users = {}
    end
    
    ##
    # Suspend the current fiber waiting for changes on specified
    # folders, if nothing changed after timeout, return an empty
    # array.
    # 
    # @param [Object] user
    # @param [Array(String)] folder_ids what to watch
    # @param [Number] timeout
    # 
    # @return [Array(String)] ids of changed folder
    # 
    def wait_for_changes(user_id, folder_ids, timeout)
      fb = Fiber.current
      
      @watching_users[user_id] = fb
      
      pair = [user_id, fb]
      
      folder_ids.each do |id|
        @watchers[id] ||= []
        @watchers[id] << pair
      end
      
      timer = EM::add_timer(timeout) do
        fb.resume([])
      end
      
      ret = Fiber.yield
      EM::cancel_timer(timer)
      ret
    ensure
      @watching_users.delete(user_id)
      folder_ids.each do |id|
        @watchers[id].delete(pair)
      end

    end
    
    
    def trigger_resync(user_id)
      if @watching_users[user_id]
        @watching_users[user_id].resume(:resync)
      end
    end
    
    
    def trigger_change(folder_id, target_user_id = nil)
      changed = [folder_id]
      
      if @watchers[folder_id]
        @watchers[folder_id].each do |(user_id, fb)|
          if !target_user_id || (user_id == target_user_id)
            fb.resume(changed)
          end
        end
      end
      
    end

  end
  
end
