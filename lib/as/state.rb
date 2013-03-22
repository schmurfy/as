require 'msgpack'

module AS
  
  
  module StateSerializer
    def load(data)
      if data
        ret = MessagePack.unpack(data).map{|(*args)| AS::State::Folder.new(*args) }
      else
        ret = []
      end
      
      AS::State.new(ret)
    end
    
    def dump(obj)
      MessagePack.pack(obj.folders)
    end
  end
  
  class State
    extend StateSerializer
    
    Contact = Struct.new(:id, :etag)
    class Folder < Struct.new(:id, :etag, :contacts)
      def initialize(*args)
        super
        self.contacts ||= {}
      end
      
      def find_contact(id)
        contacts[id]
      end
      
      def set_contact(id, etag)
        contacts[id] = etag
      end
      
      def remove_contact(id)
        contacts.delete(id)
      end
      
      def to_msgpack(packer)
        packer.write([id, etag, contacts])
      end
            
    end
    
    attr_reader :id, :folders
    
    def initialize(folders = [])
      @folders = folders
    end
    
    def add_contact(folder, contact)
      f = find_folder(folder.id)
      unless f
        f = Folder.new(folder.id, folder.etag)
        @folders << f
      end
      
      f.set_contact(contact.id, contact.etag)
    end
    
    def update_contact(folder, contact)
      f = find_folder(folder.id)
      f.set_contact(contact.id, contact.etag)
    end
    
    def remove_contact(folder, contact_id)
      f = find_folder(folder.id)
      f.remove_contact(contact_id)
    end
    
    def ==(other)
      folders == other.folders
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
      
      unless folder && new_folder
        raise AS::UnknownFolderId, folder_id
      end
      
      created = {}
      updated = {}
      
      deleted = folder.contacts.select do |id, _|
        new_folder.find_contact(id) == nil
      end
      
      new_folder.contacts.each do |id, etag|
        my_etag  = folder.find_contact(id)
        if my_etag == nil
          created[id] = etag
        elsif my_etag != etag
          updated[id] = etag
        end
      end
      
      [created, deleted, updated]
    end
    
    
  private
    def find_folder(id)
      folders.detect{|o| o.id.to_i == id.to_i }
    end
        
  end
    
end
