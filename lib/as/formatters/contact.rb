module AS
  module Formatters
    
    module Contact
      
      include AS::Helpers::XML
      
      def to_xml(data)
        data << node('C:FileAs', fileas)
        data << node('C:FirstName', firstname)
        data << node('C:LastName', lastname)
        data << node('C:CompanyName', company_name)
        # data << node('C:BusinessPhoneNumber', "0102030405")
      end
      
    end
    
  end
end
