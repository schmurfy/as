require 'virtus'
require 'securerandom'


module Testing
  
  class DummyBase
    include Virtus
    
    attribute :updated_at, Time, default: Time.now
    attribute :created_at, Time, default: Time.now
    
  end


  class Field < DummyBase
    
    attribute :group, String
    attribute :name, String
    attribute :value, String
    attribute :params, Hash, default: {}
    
    
    def self.from_vcf_field(f)
      new(group: f.group, name: f.name, value: f.value, params: f.params)
    end
  end

  class Contact < DummyBase
    
    attribute :id, Integer
    attribute :etag, String
    
    attribute :firstname, String
    attribute :lastname, String
    
    def fileas
      "#{firstname} #{lastname}"
    end
  end



  class AddressBook < DummyBase
    
    attribute :id, Integer
    attribute :displayname, String
    attribute :etag, String
    attribute :contacts, Array[Contact], default: []
    
    def find_contact(uid)
      uid = File.basename(uid, '.vcf')
      
      contacts.detect{|c| c.uid == uid.to_s }.tap do |ret|
        # p [:find, uid, ret]
      end
    end
    
    def ctag
      updated_at
    end
    
    def create_contact(uid)
      uid = File.basename(uid, '.vcf')
      Contact.new(uid: "1-#{uid}").tap do |c|
        contacts << c
      end
    end
    
    def updated_at
      Time.now.to_i
    end
    
  end
  
  
  class SavedState < DummyBase
    attribute :id, String
    attribute :state, AS::State
    
    def compare_folders(new_state)
      state.compare_folders(new_state.state)
    end
  end
  

  class User < DummyBase
    
    attribute :login, String
    attribute :addressbooks, Array[AddressBook], default: []
    attribute :savedstates, Array[SavedState], default: []
      
    def create_savedtstate
      SavedState.new(id: SecureRandom.hex(4), state: AS::State.new).tap do |s|
        self.savedstates << s
      end
    end
        
    def load_savedstate(key)
      savedstates.detect{|s| s.id == key }
    end
    
    def current_state
      SavedState.new(state: AS::State.new(self))
    end
    
    
    # def all_addressbooks
    #   # may filter with router_params, or not
    #   addressbooks
    # end
    
    
    def find_addressbook(id)
      addressbooks.detect{|b| b.id == id.to_i }
    end
    
    
    # def current_addressbook
    #   path = router_params[:book_id]
    #   addressbooks.detect{|b| b.path == path }
    # end
    
    # def current_contact
    #   uid = router_params[:contact_id]
    #   if uid && current_addressbook
    #     current_addressbook.find_contact(uid)
    #   else
    #     nil
    #   end
    # end
    
    def contacts
      # p [:all_contacts, current_addressbook.contacts.map(&:uid)]
      current_addressbook.contacts
    end
  
  private
    def router_params
      @env['router.params'] || {}
    end
    
    
  end
  
end


