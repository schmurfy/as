require_relative 'wbxml_lib'
require 'ffi'

module AS
  module WBXML
    
    class Base
      def initialize
        @state = FFI::MemoryPointer.new(:pointer)
        
        if (ret = create()) != :ok
          raise "create error: #{ret}"
        end
        
        @conv = @state.get_pointer(0)
        
        ObjectSpace.define_finalizer(self, self.class.finalize(@conv))
      end
      
      
    private
      def self.finalize(ptr)
        ->{ WBXMLLib.wbxml_conv_wbxml2xml_destroy(ptr) }
      end
            
    end
    
    
    #
    # WBXML => XML
    # 
    class Decoder < Base
      def create
        WBXMLLib.wbxml_conv_wbxml2xml_create(@state)
      end
      
      def set_language(lang)
        WBXMLLib.wbxml_conv_wbxml2xml_set_language(@conv, lang)
      end
      
      def decode(buffer)
        data = FFI::MemoryPointer.new(:uchar, buffer.bytesize)
        data.put_bytes(0, buffer, 0, data.size)
        
        output = FFI::MemoryPointer.new(:pointer)
        output_size = FFI::MemoryPointer.new(:ulong)
        
        ret = WBXMLLib.wbxml_conv_wbxml2xml_run(@conv, data, data.size, output, output_size)
        if ret == :ok
          size = output_size.get_uint(0)
          output.get_pointer(0).get_bytes(0, size)
        else
          raise RuntimeError, "failed: #{ret}"
        end
        
      end
      
    end
    
    
    #
    # XML => WBXML
    # 
    class Encoder < Base
      def create
        WBXMLLib.wbxml_conv_xml2wbxml_create(@state)
      end
      
      def set_version(version)
        WBXMLLib.wbxml_conv_xml2wbxml_set_version(@conv, version)
      end
      
      def disable_public_id!
        WBXMLLib.wbxml_conv_xml2wbxml_disable_public_id(@conv)
      end
      
      def disable_string_table!
        WBXMLLib.wbxml_conv_xml2wbxml_disable_string_table(@conv)
      end
      
      def encode(buffer)
        data = FFI::MemoryPointer.new(:uchar, buffer.bytesize)
        data.put_bytes(0, buffer, 0, data.size)
        
        output = FFI::MemoryPointer.new(:pointer)
        output_size = FFI::MemoryPointer.new(:ulong)
        
        ret = WBXMLLib.wbxml_conv_xml2wbxml_run(@conv, data, data.size, output, output_size)
        if ret == :ok
          size = output_size.get_uint(0)
          output.get_pointer(0).get_bytes(0, size)
        else
          raise RuntimeError, "failed: #{ret}"
        end
        
      end
    end
        
    class Middleware
      def initialize(app, language = :activesync)
        @app = app
        @encoder = AS::WBXML::Encoder.new
        @decoder = AS::WBXML::Decoder.new
        
        @decoder.set_language(language)
        @encoder.disable_public_id!
        @encoder.disable_string_table!
      end
      
      
      def call(env)
        body = env["rack.input"].read
        
        # decode incoming wbxml
        if body.size > 0
          env["rack.input"] = StringIO.new(@decoder.decode(body))
        end
        
        status, headers, response = @app.call(env)
        
        # and encode the result
        if response.body.size > 0
          data = @encoder.encode(response.body[0])
          response.body[0] = data
          File.write('/tmp/dump.wbxml', data)
          headers['Content-Length'] = data.bytesize.to_s
        else
          headers['Content-Length'] = "0"
        end
        
        [status, headers, response]
      end
    end
  
  end
end


if __FILE__ == $0
  encoder = AS::WBXML::Encoder.new
  decoder = AS::WBXML::Decoder.new
  
  # encoder.set_version(:v12)
  encoder.disable_public_id!
  encoder.disable_string_table!
  
  # # bin_data = "\x03\x01j\x00\x00\aVR\x030\x00\x01\x01"
  # bin_data = File.read('/tmp/out.txt')
  # decoder.set_language(:activesync)
  
  # p decoder.decode(bin_data)
  
  xml = <<-EOS
<?xml version="1.0"?>
<!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/">
<Sync xmlns="AirSync:">
<Collections>
<Collection>
<Class>Contacts</Class>
<SyncKey>{de8e5381-f732-4047-ab85-7c540b868557}3</SyncKey>
<CollectionId>v/u-36</CollectionId>
<Status>1</Status>
<Commands>
<Add>
<ServerId>30630</ServerId>
<ApplicationData>
<BusinessPhoneNumber xmlns="Contacts:">+33607089788</BusinessPhoneNumber>
<Email1Address xmlns="Contacts:">toto@free.fr</Email1Address>
<Email2Address xmlns="Contacts:">justin@aol.com</Email2Address>
<FileAs xmlns="Contacts:">Justin Mec</FileAs>
<FirstName xmlns="Contacts:">Justin</FirstName>
<JobTitle xmlns="Contacts:">Mr</JobTitle>
<LastName xmlns="Contacts:">Mec</LastName>
<MobilePhoneNumber xmlns="Contacts:">+33944332299</MobilePhoneNumber>
</ApplicationData>
</Add>
</Commands>
</Collection>
</Collections>
</Sync>
EOS
  
  data =  encoder.encode(xml)
  File.write('/tmp/dummy', data)
    
  # data = File.read('/tmp/out.txt')
  # puts decoder.decode(data)
end
