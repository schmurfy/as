module AS
  module Commands
    
    class Search < Command
      def handle!
        
        body = xml do |root|
          root << node('Search', nil, xmlns: 'Search:') do |s|
            s << node('Store') do |st|
              st << node('Status', STATUS_OK)
              st << node('Result')
            end
          end
        end
        
        @response.status = 200
        @response.body = [Ox.dump(body, with_xml: true)]
      end
    end
    
  end
end
