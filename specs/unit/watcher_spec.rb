require File.expand_path('../../spec_helper', __FILE__)

require 'active_support/core_ext'

describe 'Watcher' do
  before do
    @folder_id = 45
    @user1_id = 1
    @user2_id = 2
    
    @watcher = AS::Watcher.instance
    @watcher.reset()
  end
  
  should 'wakeup on event' do
    EM::add_timer(0.1) do
      @watcher.trigger_change(@folder_id)
    end
    
    elapsed = time_block do
      @watcher.wait_for_changes(@user1_id, [@folder_id], 1)
    end
    
    elapsed.should.be.close?(100, 2)
  end
  
  
  should 'wakeup specific user' do
    EM::add_timer(0.05) do
      @watcher.trigger_change(@folder_id, @user2_id)
    end
    
    elapsed1 = nil
    elapsed2 = nil
    
    fb1 = Fiber.new do
      elapsed1 = time_block do
        @watcher.wait_for_changes(@user1_id, [@folder_id], 0.2)
      end
    end.resume
    
    fb2 = Fiber.new do
      elapsed2 = time_block do
        @watcher.wait_for_changes(@user2_id, [@folder_id], 0.2)
      end
    end.resume
    
    wait(0.5) do
      elapsed1.should.be.close?(200, 2)
      elapsed2.should.be.close?(50, 2)
    end
  end
end
