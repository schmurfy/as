module AS
  class Command
    
    STATUS_OK               = 1
    
    FOLDER_TYPE_CONTACTS_DEFAULT = 9
    FOLDER_TYPE_CONTACTS = 14
    
    def initialize(xml, req, response)
      @req = req
      @response = response
      @xml = xml
      @status = STATUS_OK
    end
    
    def sync_key
      @sync_key ||= @xml.locate('*/SyncKey/?[0]').first
    end
        
  protected
    
    def current_user
      @req.env['as.user']
    end
    
    def initial_request
      sync_key == '0'
    end
        
    def savedstate
      if sync_key == '0'
        @savedstate ||= current_user.create_savedtstate
      else
        @savedstate ||= current_user.load_savedstate(sync_key)
      end
    end
    
    def find_text_node(root_element, path)
      tmp = root_element.locate("#{path}/?[0]")
      if tmp
        tmp[0]
      else
        nil
      end
    end
        
    def xml()
      Ox::Document.new(version: '1.0', encoding: 'utf-8').tap do |x|
        x << Ox::DocType.new(%{ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/"})
        yield(x)
      end
    end
    
    def node(name, text = nil, attributes = {})
      Ox::Element.new(name).tap do |n|
        
        attributes.each do |name, value|
          n[name] = value
        end
        
        if block_given?
          yield(n)
        else
          n << text.to_s
        end
      end
    end
    
  end
end
