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
  
  it 'can be dumped and restored' do
    state = AS::State.new(@user)
    data = AS::State.dump(state)
    state2 = AS::State.load(data)
    
    
    state2.folders.size.should == 2
    state2.folders.should == [
      AS::State::Folder.new(2, 'r56b'),
      AS::State::Folder.new(4, 'y7lo21')
    ]
  end
  
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
  
  
  describe 'contacts compare' do
    before do
      @user.addressbooks[0].contacts = [
        build(:contact),
        build(:contact),
        build(:contact)
      ]
      
      @user.addressbooks[1].contacts = [
        build(:contact)
      ]
    end
    
    should 'find created' do
      state = AS::State.new(@user)
      new_contact = build(:contact)
      
      @user.addressbooks[0].contacts << new_contact
      state2 = AS::State.new(@user)
      
      created, deleted, updated = state.compare_contacts(@user.addressbooks[0].id, state2)
      created.should == {new_contact.id => new_contact.etag}
      deleted.should == {}
      updated.should == {}
    end
    
    should 'find deleted' do
      target = @user.addressbooks[0].contacts[0]
      state = AS::State.new(@user)
      @user.addressbooks[0].contacts.shift
      state2 = AS::State.new(@user)
      
      created, deleted, updated = state.compare_contacts(@user.addressbooks[0].id, state2)
      created.should == {}
      deleted.should == {target.id => target.etag}
      updated.should == {}
    end
    
    should 'find updated' do
      target = @user.addressbooks[0].contacts[1]
      
      state = AS::State.new(@user)
      target.etag = 'something_else'
      state2 = AS::State.new(@user)
      
      created, deleted, updated = state.compare_contacts(@user.addressbooks[0].id, state2)
      created.should == {}
      deleted.should == {}
      updated.should == {target.id => 'something_else'}
    end
    
    should 'find created, deted and updated scoped by folder' do
      delete_target = @user.addressbooks[1].contacts[0]
      update_target = @user.addressbooks[0].contacts[0]
      created_target = build(:contact)
      
      state = AS::State.new(@user)
      update_target.etag = 'uzrt'
      @user.addressbooks[1].contacts.shift
      @user.addressbooks[1].contacts << created_target
      state2 = AS::State.new(@user)
      
      created, deleted, updated = state.compare_contacts(@user.addressbooks[0].id, state2)
      created.should == {}
      deleted.should == {}
      updated.should == {update_target.id => update_target.etag}
      
      created, deleted, updated = state.compare_contacts(@user.addressbooks[1].id, state2)
      created.should == {created_target.id => created_target.etag}
      deleted.should == {delete_target.id => delete_target.etag}
      updated.should == {}
    end
    
  end

  
end
