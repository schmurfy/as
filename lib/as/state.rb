module AS
  class State
    Contact = Struct.new(:id, :etag)
    class Folder < Struct.new(:id, :etag, :contacts)
      def initialize(*args)
        super
        self.contacts ||= []
      end
      
      def find_contact(id)
        contacts.detect{|o| o.id == id }
      end
    end
    
    attr_reader :id, :folders, :folder_id
    
    def initialize(user = nil, folder_id = nil)
      if user
        @folders = user.addressbooks.select{|f| !folder_id || (f.id == folder_id) }.map do |book|
          contacts = book.contacts.map{|c| Contact.new(c.id, c.etag) }
          Folder.new(book.id, book.etag, contacts)
        end
        
      else
        @folders = []
      end
    end
    
    def compare_folders(new_state)
      created = new_state.folders.select do |f|
        find_folder(f.id) == nil
      end
      
      deleted = folders.select do |f|
        new_state.send(:find_folder, f.id) == nil
      end
      
      
      updated = new_state.folders.select do |f|
        my_folder = find_folder(f.id)
        my_folder && (my_folder.etag != f.etag)
      end
      
      [created, deleted, updated]
    end
    
    
    def compare_contacts(folder_id, new_state)
      folder = find_folder(folder_id) || Folder.new(folder_id)
      new_folder = new_state.send(:find_folder, folder_id)
      
      raise "unknown folder_id: #{folder_id}" unless folder && new_folder
      
      created = new_folder.contacts.select do |c|
        folder.find_contact(c.id) == nil
      end
      
      deleted = folder.contacts.select do |c|
        new_folder.find_contact(c.id) == nil
      end
      
      updated = new_folder.contacts.select do |c|
        my_contact = folder.find_contact(c.id)
        my_contact && (my_contact.etag != c.etag)
      end

      
      [created, deleted, updated]
    end
    
    
    def dump
      Ox.dump(self)
    end
    
    def self.load(data)
      Ox.parse(data)
    end
    
    
  private
    def find_folder(id)
      folders.detect{|o| o.id.to_i == id.to_i }
    end
        
  end
    
end
