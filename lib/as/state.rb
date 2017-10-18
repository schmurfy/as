require 'msgpack'

module AS
  
  
  module StateSerializer
    def load(data)
      if data
        ret = MessagePack.unpack(data).map do |(id, etag, serialized_contacts)|
          contacts = serialized_contacts.inject({}) do |h, (id, binary_etag)|
            h[id] = AS::State::Folder.md5_binary_to_str(binary_etag)
            h
          end
          
          AS::State::Folder.new(id, etag, contacts)
        end
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
        serialized_contacts = contacts.inject({}) do |h, (id, etag)|
          h[id] = self.class.md5_str_to_binary(etag)
          h
        end
        
        packer.write([id, etag, serialized_contacts])
      end
      
    private
      def self.md5_binary_to_str(str)
        str.bytes.map do |n|
          n.to_s(16).rjust(2, '0')
        end.join.upcase
      end
      
      # ff => \xff
      def self.md5_str_to_binary(str)
        str.chars.each_slice(2).map do |(c1, c2)|
          "#{c1}#{c2}".to_i(16)
        end.pack("C*")
      end
            
    end
    
    attr_reader :folders
    
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
    
    def remove_contact(folder_id, contact_id)
      f = find_folder(folder_id)
      f.remove_contact(contact_id)
    end
    
    def to_s
      dump(self)
    end

    def ==(other)
      self.to_s == other.to_s
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
