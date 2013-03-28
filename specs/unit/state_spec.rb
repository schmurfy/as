require File.expand_path('../../spec_helper', __FILE__)

describe 'State' do
  before do
    @user = Testing::User.new(login: "john", addressbooks: [
        Testing::AddressBook.new(id: 2, etag: "f5bb32"),
        Testing::AddressBook.new(id: 4, etag: "65bc72")
      ])
  end
  
  it 'can build and empty state from user' do
    @user.addressbooks[0].contacts = [
      build(:contact)
    ]

    
    state = @user.current_state()
    state.folders.size.should == 2
    state.folders.should == [
      AS::State::Folder.new(2, 'f5bb32'),
      AS::State::Folder.new(4, '65bc72')
    ]
  end
  
  it 'can be dumped and restored (folders list)' do
    
    folder = @user.addressbooks[1]
    folder.contacts = [
      build(:contact, etag: 'ff6e34'),
      build(:contact, etag: 'bc6a70'),
    ]
    
    state = @user.current_state()
    data = AS::State.dump(state)
    state2 = AS::State.load(data)
    
    
    state2.folders.size.should == 2
    state2.folders.should == [
      AS::State::Folder.new(2, 'f5bb32'),
      AS::State::Folder.new(4, '65bc72')
    ]
  end
  
  should 'convert md5 string to binary' do
    AS::State::Folder.md5_str_to_binary("ffe356").should ==
      "\xff\xe3\x56".force_encoding('ascii-8bit')
  end
  
  should 'convert md5 bonary to string' do
    AS::State::Folder.md5_binary_to_str("\xff\xe3\x56").should ==
      "ffe356".force_encoding('ascii-8bit')
  end

  
  it 'can be dumped and restored (contacts list)' do
    
    c1 = build(:contact, etag: 'ff6e34')
    c2 = build(:contact, etag: 'bc6a70')
    
    folder = @user.addressbooks[1]
    folder.contacts = [
      c1,
      c2
    ]
    
    state = @user.current_state(folder.id)
    data = AS::State.dump(state)
    state2 = AS::State.load(data)
    
    
    state2.folders.size.should == 1
    state2.folders.should == [
      AS::State::Folder.new(4, '65bc72', {
          c1.id => 'ff6e34',
          c2.id => 'bc6a70'
        })
    ]
  end

  
  describe 'folders compare' do
    should 'find created' do
      state = @user.current_state()
      @user.addressbooks << Testing::AddressBook.new(id: 3, etag: "test")
      state2 = @user.current_state()
      created, deleted, updated = state.compare_folders(state2)
      created.should == [AS::State::Folder.new(3, 'test')]
      deleted.should == []
      updated.should == []
    end
    
    should 'find deleted' do
      state = @user.current_state()
      @user.addressbooks.shift
      state2 = @user.current_state()
      
      created, deleted, updated = state.compare_folders(state2)
      created.should == []
      deleted.should == [AS::State::Folder.new(2, 'f5bb32')]
      updated.should == []
    end
    
    should 'find updated' do
      state = @user.current_state()
      @user.addressbooks[1].etag = 'castor'
      state2 = @user.current_state()
      
      created, deleted, updated = state.compare_folders(state2)
      created.should == []
      deleted.should == []
      updated.should == [AS::State::Folder.new(4, 'castor')]
    end
    
    should 'find created, deted and updated' do
      state = @user.current_state()
      @user.addressbooks[1].etag = 'uzrt'
      @user.addressbooks << Testing::AddressBook.new(id: 35, etag: "test")
      @user.addressbooks.shift
      state2 = @user.current_state()
      
      created, deleted, updated = state.compare_folders(state2)
      created.should == [AS::State::Folder.new(35, 'test')]
      deleted.should == [AS::State::Folder.new(2, 'f5bb32')]
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
      
      @folder1_id = @user.addressbooks[0].id
      @folder2_id = @user.addressbooks[1].id
    end
    
    should 'find created' do
      state = @user.current_state(@folder1_id)
      new_contact = build(:contact)
      
      @user.addressbooks[0].contacts << new_contact
      state2 = @user.current_state(@folder1_id)
      
      created, deleted, updated = state.compare_contacts(@folder1_id, state2)
      created.should == {new_contact.id => new_contact.etag}
      deleted.should == {}
      updated.should == {}
    end
    
    should 'find deleted' do
      target = @user.addressbooks[0].contacts[0]
      state = @user.current_state(@folder1_id)
      @user.addressbooks[0].contacts.shift
      state2 = @user.current_state(@folder1_id)
      
      created, deleted, updated = state.compare_contacts(@folder1_id, state2)
      created.should == {}
      deleted.should == {target.id => target.etag}
      updated.should == {}
    end
    
    should 'find updated' do
      target = @user.addressbooks[0].contacts[1]
      
      state = @user.current_state(@folder1_id)
      target.etag = 'something_else'
      state2 = @user.current_state(@folder1_id)
      
      created, deleted, updated = state.compare_contacts(@folder1_id, state2)
      created.should == {}
      deleted.should == {}
      updated.should == {target.id => 'something_else'}
    end
    
    should 'find created, deted and updated scoped by folder' do
      delete_target = @user.addressbooks[1].contacts[0]
      update_target = @user.addressbooks[0].contacts[0]
      created_target = build(:contact)
      
      state1 = @user.current_state(@folder1_id)
      state2 = @user.current_state(@folder2_id)
      
      update_target.etag = 'uzrt'
      @user.addressbooks[1].contacts.shift
      @user.addressbooks[1].contacts << created_target
      
      state12 = @user.current_state(@folder1_id)
      created, deleted, updated = state1.compare_contacts(@folder1_id, state12)
      created.should == {}
      deleted.should == {}
      updated.should == {update_target.id => update_target.etag}
      
      
      state22 = @user.current_state(@folder2_id)
      created, deleted, updated = state2.compare_contacts(@folder2_id, state22)
      created.should == {created_target.id => created_target.etag}
      deleted.should == {delete_target.id => delete_target.etag}
      updated.should == {}
    end
    
  end

  
end
