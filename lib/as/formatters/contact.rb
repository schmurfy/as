module AS
  module Formatters
    
    module Contact
      
      include AS::Helpers::XML
      
      def attributes_mapping
        @mapping ||= {
          'Title'       => 'title',
          'FileAs'      => 'fileas',
          'FirstName'   => 'firstname',
          'LastName'    => 'lastname',
          'CompanyName' => 'company_name'
        }
      end
      
      def to_xml(data)
        attributes_mapping.each do |as_name, accessor_name|
          value = send(accessor_name)
          if value != nil
            data << node(as_name, value, xmlns: 'Contacts:')
          end
        end
        
      end
      
      def update_from_xml(data_node)
        attributes_mapping.each do |as_name, accessor_name|
          value = find_text_node(data_node, as_name)
          send("#{accessor_name}=", value)
        end
      end
            
    end
    
  end
end
