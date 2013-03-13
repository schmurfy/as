require File.expand_path('../../../spec_helper', __FILE__)

describe 'Formatters::Contact' do
  
  should 'encode contact to xml' do
    c = build(:contact, title: 'Mr')
    
    parent_node = Ox::Element.new('Dummy')
    
    c.to_xml(parent_node)
    Ox.dump(parent_node).should == unindent(<<-EOS)

      <Dummy>
        <C:Title>#{c.title}</C:Title>
        <C:FileAs>#{c.fileas}</C:FileAs>
        <C:FirstName>#{c.firstname}</C:FirstName>
        <C:LastName>#{c.lastname}</C:LastName>
        <C:CompanyName>#{c.company_name}</C:CompanyName>
      </Dummy>
    EOS
    
  end
  
end
