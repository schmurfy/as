require 'virtus'
require 'securerandom'


module Testing
  
  class DummyBase
    include Virtus
    
    attribute :updated_at, Time, default: Time.now
    attribute :created_at, Time, default: Time.now
    
  end



  class Contact < DummyBase
    
    include AS::Formatters::Contact
    
    attribute :id, Integer
    attribute :etag, String
    
    attribute :firstname, String
    attribute :lastname, String
    attribute :company_name, String
    
    def fileas
      "#{firstname} #{lastname}"
    end
  end



  class AddressBook < DummyBase
    
    attribute :id, Integer
    attribute :displayname, String
    attribute :etag, String
    attribute :contacts, Array[Contact], default: []
    
    def find_contact(id)
      contacts.detect{|c| c.id == id.to_i }
    end
    
    # def ctag
    #   updated_at
    # end
    
    # def create_contact(uid)
    #   uid = File.basename(uid, '.vcf')
    #   Contact.new(uid: "1-#{uid}").tap do |c|
    #     contacts << c
    #   end
    # end
    
    # def updated_at
    #   Time.now.to_i
    # end
    
  end
  
  
  class SavedState < DummyBase
    attribute :id, String
    attribute :state, AS::State
    
    def compare_folders(new_state)
      state.compare_folders(new_state.state)
    end
    
    def compare_contacts(folder_id, new_state)
      state.compare_contacts(folder_id, new_state.state)
    end
    
    def folder_id
      state.folder_id
    end
  end
  

  class User < DummyBase
    
    attribute :login, String
    attribute :addressbooks, Array[AddressBook], default: []
    
    attribute :folder_states, Array[SavedState], default: []
    attribute :contact_states, Array[SavedState], default: []
    
    def create_savedtstate(folder_id = nil)
      s = SavedState.new(id: SecureRandom.hex(4), state: AS::State.new(nil, folder_id))
      
      if folder_id
        self.contact_states << s
      else
        self.folder_states << s
      end
      
      s
    end
        
    def load_savedstate(type, key)
      if type == :folders
        folder_states.detect{|s| s.id == key }
      else
        contact_states.detect{|s| s.id == key }
      end
    end
    
    def update_savedstate(type, key, new_state)
      raise "Invalid key: #{key}" if key == '0'
      
      if type == :folders
        self.folder_states = (folder_states || []).reject{|s| s.id == key }
        new_state.id = key
        self.folder_states << new_state
      else
        self.contact_states = (contact_states || []).reject{|s| s.id == key }
        new_state.id = key
        self.contact_states << new_state
      end
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
    
    def find_contact(folder_id, id)
      book = find_addressbook(folder_id)
      if book
        book.find_contact(id)
      end
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


