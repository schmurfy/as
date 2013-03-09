module AS
  class State    
    Folder = Struct.new(:id, :etag, :contacts)
    Contact = Struct.new(:id, :etag)
    
    attr_reader :id, :folders
    
    def initialize(user = nil)
      if user
        @folders = user.addressbooks.map do |book|
          Folder.new(book.id, book.etag)
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
    
    def dump
      Ox.dump(self)
    end
    
    def self.load(data)
      Ox.parse(data)
    end
    
    
  private
    def find_folder(id)
      folders.detect{|o| o.id == id }
    end
    
  end
    
end
