module AS
  class Command
    include AS::Helpers::XML
    
    STATUS_OK               = 1
    
    FOLDER_TYPE_CONTACTS_DEFAULT = 9
    FOLDER_TYPE_CONTACTS = 14
    
    def initialize(xml, req, response)
      @req = req
      @response = response
      @xml = xml
      @status = STATUS_OK
    end
        
  protected
    
    def suspend(delay)
      fb = Fiber.current
      
      EM::add_timer(delay) do
        fb.Resume
      end
      
      Fiber.yield
    end
    
    def current_user
      @req.env['as.user']
    end
    
    def current_state
      @current_state ||= current_user.current_state()
    end
    
    def initial_request
      sync_key == '0'
    end
        
    def find_text_node(root_element, path)
      tmp = root_element.locate("#{path}/?[0]")
      if tmp
        tmp[0]
      else
        nil
      end
    end
    
  end
end
