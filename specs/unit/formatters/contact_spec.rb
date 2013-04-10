# encoding: utf-8

require File.expand_path('../../../spec_helper', __FILE__)

describe 'Formatters::Contact' do
  before do
    @contact = c = build(:contact, title: 'Mr', firstname: 'René', note: "A long\nnote")
    @expected_xml = unindent(<<-EOS)

      <Dummy>
        <Title xmlns="Contacts:">#{c.title}</Title>
        <FileAs xmlns="Contacts:">#{c.fileas}</FileAs>
        <FirstName xmlns="Contacts:">#{c.firstname}</FirstName>
        <LastName xmlns="Contacts:">#{c.lastname}</LastName>
        <CompanyName xmlns="Contacts:">#{c.company_name}</CompanyName>
        <Body xmlns="AirSyncBase:">
          <Type>1</Type>
          <Data>A long
      note</Data>
        </Body>
      </Dummy>
    EOS
  end
  
  should 'encode contact to xml' do
    parent_node = Ox::Element.new('Dummy')
    
    @contact.to_xml(parent_node)
    result = Ox.dump(parent_node)
    # ox will return an ascii-8bits string
    result.force_encoding('utf-8').should == @expected_xml
  end
  
  
  should 'decode contact xml' do
    node = Ox.load(@expected_xml)
    
    @contact.firstname = ""
    @contact.note = ""
    @contact.update_from_xml(node)
    @contact.firstname.should == "René"
    @contact.note.should == "A long\nnote"
    @contact
  end
  
end
