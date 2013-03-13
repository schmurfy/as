module AS
  module Helpers
    
    module XML
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
end
