require File.expand_path('../../../spec_helper', __FILE__)

describe 'Formatters::Contact' do
  
  should 'encode contact to xml' do
    c = build(:contact, title: 'Mr')
    
    parent_node = Ox::Element.new('Dummy')
    
    c.to_xml(parent_node)
    Ox.dump(parent_node).should == unindent(<<-EOS)

      <Dummy>
        <Title xmlns="Contacts:">#{c.title}</Title>
        <FileAs xmlns="Contacts:">#{c.fileas}</FileAs>
        <FirstName xmlns="Contacts:">#{c.firstname}</FirstName>
        <LastName xmlns="Contacts:">#{c.lastname}</LastName>
        <CompanyName xmlns="Contacts:">#{c.company_name}</CompanyName>
      </Dummy>
    EOS
    
  end
  
end
