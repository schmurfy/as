require File.expand_path('../../spec_helper', __FILE__)

describe 'State' do
  before do
    @user = Testing::User.new(login: "john", addressbooks: [
        Testing::AddressBook.new(id: 2, etag: "r56b"),
        Testing::AddressBook.new(id: 4, etag: "y7lo21")
      ])
  end
  
  it 'can build state from user' do
    state = AS::State.new(@user)
    state.folders.size.should == 2
    state.folders.should == [
      AS::State::Folder.new(2, 'r56b'),
      AS::State::Folder.new(4, 'y7lo21')
    ]
  end
  
  # it 'can be dumped and restored' do
  #   state = AS::State.new(@user)
  #   data = state.dump
  #   p data
  #   state2 = AS::State.load(data)
    
    
  #   state2.folders.size.should == 2
  #   state2.folders.should == [
  #     AS::State::Folder.new(2, 'r56b'),
  #     AS::State::Folder.new(4, 'y7lo21')
  #   ]
  # end
  
  describe 'folders compare' do
    should 'find created' do
      state = AS::State.new(@user)
      @user.addressbooks << Testing::AddressBook.new(id: 3, etag: "test")
      state2 = AS::State.new(@user)
      
      created, deleted, updated = state.compare_folders(state2)
      created.should == [AS::State::Folder.new(3, 'test')]
      deleted.should == []
      updated.should == []
    end
    
    should 'find deleted' do
      state = AS::State.new(@user)
      @user.addressbooks.shift
      state2 = AS::State.new(@user)
      
      created, deleted, updated = state.compare_folders(state2)
      created.should == []
      deleted.should == [AS::State::Folder.new(2, 'r56b')]
      updated.should == []
    end
    
    should 'find updated' do
      state = AS::State.new(@user)
      @user.addressbooks[1].etag = 'castor'
      state2 = AS::State.new(@user)
      
      created, deleted, updated = state.compare_folders(state2)
      created.should == []
      deleted.should == []
      updated.should == [AS::State::Folder.new(4, 'castor')]
    end
    
    should 'find created, deted and updated' do
      state = AS::State.new(@user)
      @user.addressbooks[1].etag = 'uzrt'
      @user.addressbooks << Testing::AddressBook.new(id: 35, etag: "test")
      @user.addressbooks.shift
      state2 = AS::State.new(@user)
      
      created, deleted, updated = state.compare_folders(state2)
      created.should == [AS::State::Folder.new(35, 'test')]
      deleted.should == [AS::State::Folder.new(2, 'r56b')]
      updated.should == [AS::State::Folder.new(4, 'uzrt')]
    end
  end

  
end
