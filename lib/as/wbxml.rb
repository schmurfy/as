require 'ffi'

module AS
  module WBXMLLib
    extend FFI::Library
    
    ffi_lib('wbxml2')
    
    # typedef enum WBXMLError_e {
    #     /* Generic Errors */
    #     WBXML_OK = 0,       /**< No Error */
    #     WBXML_NOT_ENCODED = 1,  /**< Not an error; just a special internal return code */
    #     WBXML_ERROR_ATTR_TABLE_UNDEFINED = 10,
    #     WBXML_ERROR_BAD_DATETIME =         11,
    #     WBXML_ERROR_BAD_PARAMETER =        12,    
    #     WBXML_ERROR_INTERNAL =             13,
    #     WBXML_ERROR_LANG_TABLE_UNDEFINED = 14,
    #     WBXML_ERROR_NOT_ENOUGH_MEMORY =    15,
    #     WBXML_ERROR_NOT_IMPLEMENTED =      16,
    #     WBXML_ERROR_TAG_TABLE_UNDEFINED =  17,
    #     WBXML_ERROR_B64_ENC =              18,
    #     WBXML_ERROR_B64_DEC =              19,
    # #if defined( WBXML_SUPPORT_WV )
    #     WBXML_ERROR_WV_DATETIME_FORMAT = 20,
    # #endif /* WBXML_SUPPORT_WV */
    #     WBXML_ERROR_NO_CHARSET_CONV =   30,
    #     WBXML_ERROR_CHARSET_STR_LEN =   31,
    #     WBXML_ERROR_CHARSET_UNKNOWN =   32,
    #     WBXML_ERROR_CHARSET_CONV_INIT = 33,
    #     WBXML_ERROR_CHARSET_CONV =      34,
    #     WBXML_ERROR_CHARSET_NOT_FOUND = 35,
    #     /* WBXML Parser Errors */    
    #     WBXML_ERROR_ATTR_VALUE_TABLE_UNDEFINED =                  40,
    #     WBXML_ERROR_BAD_LITERAL_INDEX =                           41,
    #     WBXML_ERROR_BAD_NULL_TERMINATED_STRING_IN_STRING_TABLE =  42,
    #     WBXML_ERROR_BAD_OPAQUE_LENGTH =                           43,
    #     WBXML_ERROR_EMPTY_WBXML =                                 44,
    #     WBXML_ERROR_END_OF_BUFFER =                               45,
    #     WBXML_ERROR_ENTITY_CODE_OVERFLOW =                        46,
    #     WBXML_ERROR_EXT_VALUE_TABLE_UNDEFINED =                   47,
    #     WBXML_ERROR_INVALID_STRTBL_INDEX =                        48,
    #     WBXML_ERROR_LITERAL_NOT_NULL_TERMINATED_IN_STRING_TABLE = 49,
    #     WBXML_ERROR_NOT_NULL_TERMINATED_INLINE_STRING =           50,
    #     WBXML_ERROR_NULL_PARSER =                                 51,
    #     WBXML_ERROR_NULL_STRING_TABLE =                           52,
    #     WBXML_ERROR_STRING_EXPECTED =                             53,
    #     WBXML_ERROR_STRTBL_LENGTH =                               54,   
    #     WBXML_ERROR_UNKNOWN_ATTR =            60,
    #     WBXML_ERROR_UNKNOWN_ATTR_VALUE =      61,
    #     WBXML_ERROR_UNKNOWN_EXTENSION_TOKEN = 62,
    #     WBXML_ERROR_UNKNOWN_EXTENSION_VALUE = 63,
    #     WBXML_ERROR_UNKNOWN_PUBLIC_ID =       64,
    #     WBXML_ERROR_UNKNOWN_TAG =             65,
    #     WBXML_ERROR_UNVALID_MBUINT32 = 70,
    # #if defined( WBXML_SUPPORT_WV )
    #     WBXML_ERROR_WV_INTEGER_OVERFLOW = 80,
    # #endif /* WBXML_SUPPORT_WV */
    #     /* WBXML Encoder Errors */
    #     WBXML_ERROR_ENCODER_APPEND_DATA = 90,
    #     WBXML_ERROR_STRTBL_DISABLED =      100,
    #     WBXML_ERROR_UNKNOWN_XML_LANGUAGE = 101,
    #     WBXML_ERROR_XML_NODE_NOT_ALLOWED = 102,
    #     WBXML_ERROR_XML_NULL_ATTR_NAME =   103,
    #     WBXML_ERROR_XML_PARSING_FAILED =   104,
    # #if defined( WBXML_SUPPORT_SYNCML )
    #     WBXML_ERROR_XML_DEVINF_CONV_FAILED = 110,
    # #endif /* WBXML_SUPPORT_WV */
    #     WBXML_ERROR_NO_XMLPARSER =           120,
    #     WBXML_ERROR_XMLPARSER_OUTPUT_UTF16 = 121,
    # } WBXMLError;
  
    # typedef enum WBXMLLanguage_e {
    #     WBXML_LANG_UNKNOWN = 0,     /**< Unknown / Not Specified */
        
    #     WBXML_LANG_WML10 = 1101,           /**< WML 1.0 */
    #     WBXML_LANG_WML11 = 1102,           /**< WML 1.1 */
    #     WBXML_LANG_WML12 = 1103,           /**< WML 1.2 */
    #     WBXML_LANG_WML13 = 1104,           /**< WML 1.3 */

    # } WBXMLLanguage;
    
    # typedef enum WBXMLVersion_e {
    #     WBXML_VERSION_UNKNOWN = -1, /**< Unknown WBXML Version */
    #     WBXML_VERSION_10 = 0x00,    /**< WBXML 1.0 Token */
    #     WBXML_VERSION_11 = 0x01,    /**< WBXML 1.1 Token */
    #     WBXML_VERSION_12 = 0x02,    /**< WBXML 1.2 Token */
    #     WBXML_VERSION_13 = 0x03     /**< WBXML 1.3 Token */
    # } WBXMLVersion;
    
    # typedef enum WBXMLGenXMLType_e {
    #     WBXML_GEN_XML_COMPACT   = 0,  /**< Compact XML generation */
    #     WBXML_GEN_XML_INDENT    = 1,  /**< Indented XML generation */
    #     WBXML_GEN_XML_CANONICAL = 2   /**< Canonical XML generation */
    # } WBXMLGenXMLType;
    
    # typedef enum WBXMLCharsetMIBEnum_e {
    #   WBXML_CHARSET_UNKNOWN         = 0,       /**< Unknown Charset */
    #   WBXML_CHARSET_US_ASCII        = 3,       /**< US-ASCII */
    #   WBXML_CHARSET_ISO_8859_1      = 4,       /**< ISO-8859-1 */
    #   WBXML_CHARSET_ISO_8859_2      = 5,       /**< ISO-8859-2 */
    #   WBXML_CHARSET_ISO_8859_3      = 6,       /**< ISO-8859-3 */
    #   WBXML_CHARSET_ISO_8859_4      = 7,       /**< ISO-8859-4 */
    #   WBXML_CHARSET_ISO_8859_5      = 8,       /**< ISO-8859-5 */
    #   WBXML_CHARSET_ISO_8859_6      = 9,       /**< ISO-8859-6 */
    #   WBXML_CHARSET_ISO_8859_7      = 10,      /**< ISO-8859-7 */
    #   WBXML_CHARSET_ISO_8859_8      = 11,      /**< ISO-8859-8 */
    #   WBXML_CHARSET_ISO_8859_9      = 12,      /**< ISO-8859-9 */
    #   WBXML_CHARSET_SHIFT_JIS       = 17,      /**< Shift_JIS */
    #   WBXML_CHARSET_UTF_8           = 106,     /**< UTF-8 */
    #   WBXML_CHARSET_ISO_10646_UCS_2 = 1000,    /**< ISO-10646-UCS-2 */
    #   WBXML_CHARSET_UTF_16          = 1015,    /**< UTF-16 */
    #   WBXML_CHARSET_BIG5            = 2026     /**< Big5 */
    # } WBXMLCharsetMIBEnum;
    
    # typedef struct WBXMLGenXMLParams_s {
    #     WBXMLGenXMLType gen_type;    /**< WBXML_GEN_XML_COMPACT | WBXML_GEN_XML_INDENT | WBXML_GEN_XML_CANONICAL (Default: WBXML_GEN_XML_INDENT) */
    #     WBXMLLanguage lang;          /**< Force document Language (overwrite document Public ID) */
    #     WBXMLCharsetMIBEnum charset; /**< Set document Language (does not overwrite document character set) */
    #     WB_UTINY indent;             /**< Indentation Delta, when using WBXML_GEN_XML_INDENT Generation Type (Default: 0) */
    #     WB_BOOL keep_ignorable_ws;   /**< Keep Ignorable Whitespaces (Default: FALSE) */
    # } WBXMLGenXMLParams;
    
    # /**
    #  * @brief Convert WBXML to XML
    #  * @param wbxml     [in] WBXML Document to convert
    #  * @param wbxml_len [in] Length of WBXML Document
    #  * @param xml       [out] Resulting XML Document
    #  * @param xml_len   [out] XML Document length
    #  * @param params    [in] Parameters (if NULL, default values are used)
    #  * @return WBXML_OK if conversion succeeded, an Error Code otherwise
    #  */
    # WBXML_DECLARE(WBXMLError) wbxml_conv_wbxml2xml_withlen(WB_UTINY  *wbxml,
    #   WB_ULONG   wbxml_len,
    #   WB_UTINY **xml,
    #   WB_ULONG  *xml_len,
    #   WBXMLGenXMLParams *params) LIBWBXML_DEPRECATED;
    
    #define WB_BOOL unsigned char
    #define WB_UTINY unsigned char
    #define WB_TINY char
    #define WB_ULONG unsigned int
    #define WB_LONG int

    
    # WBXML_DECLARE(WBXMLError) wbxml_conv_xml2wbxml_withlen(
    #   WB_UTINY  *xml,
    #   WB_ULONG   xml_len,
    #   WB_UTINY **wbxml,
    #   WB_ULONG  *wbxml_len,
    #   WBXMLGenWBXMLParams *params) LIBWBXML_DEPRECATED;
    



=begin NEW API XML => WBXML
    /**
     * @brief Create a new WBXML to XML converter with the default configuration.
     * @param conv [out] a reference to the pointer of the new converter
     * @return WBXML_OK if conversion succeeded, an Error Code otherwise
     */
    WBXML_DECLARE(WBXMLError) wbxml_conv_xml2wbxml_create(WBXMLConvXML2WBXML **conv);

    /**
     * @brief Set the WBXML version (default: 1.3).
     * @param conv   [in] the converter
     * @param indent [in] the number of blanks
     */
    WBXML_DECLARE(void) wbxml_conv_xml2wbxml_set_version(WBXMLConvXML2WBXML *conv,
                                                         WBXMLVersion wbxml_version);

    /**
     * @brief Enable whitespace preservation (default: FALSE/DISABLED).
     * @param conv     [in] the converter
     */
    WBXML_DECLARE(void) wbxml_conv_xml2wbxml_enable_preserve_whitespaces(WBXMLConvXML2WBXML *conv);

    /**
     * @brief Disable string table (default: TRUE/ENABLED).
     * @param conv     [in] the converter
     */
    WBXML_DECLARE(void) wbxml_conv_xml2wbxml_disable_string_table(WBXMLConvXML2WBXML *conv);

    /**
     * @desription: Disable public ID (default: TRUE/ENABLED).
     *              Usually you don't want to produce WBXML documents which are
     *              really anonymous. You want a known public ID or a DTD name
     *              to determine the document type. Some specifications like
     *              Microsoft's ActiveSync explicitely require fully anonymous
     *              WBXML documents. If you need this then you must disable
     *              the public ID mechanism.
     * @param conv     [in] the converter
     */
    WBXML_DECLARE(void) wbxml_conv_xml2wbxml_disable_public_id(WBXMLConvXML2WBXML *conv);

    /**
     * @brief Convert XML to WBXML
     * @param conv      [in] the converter
     * @param xml       [in] XML Document to convert
     * @param xml_len   [in] Length of XML Document
     * @param wbxml     [out] Resulting WBXML Document
     * @param wbxml_len [out] Length of resulting WBXML Document
     * @return WBXML_OK if conversion succeeded, an Error Code otherwise
     */
    WBXML_DECLARE(WBXMLError) wbxml_conv_xml2wbxml_run(WBXMLConvXML2WBXML *conv,
                                                       WB_UTINY  *xml,
                                                       WB_ULONG   xml_len,
                                                       WB_UTINY **wbxml,
                                                       WB_ULONG  *wbxml_len);

    /**
     * @brief Destroy the converter object.
     * @param [in] the converter
     */
    WBXML_DECLARE(void) wbxml_conv_xml2wbxml_destroy(WBXMLConvXML2WBXML *conv);
    
=end

    
    
=begin NEW API WBXML => XML
    # /**
    #  * @brief Create a new WBXML to XML converter with the default configuration.
    #  * @param conv [out] a reference to the pointer of the new converter
    #  * @return WBXML_OK if conversion succeeded, an Error Code otherwise
    #  */
    # WBXML_DECLARE(WBXMLError) wbxml_conv_wbxml2xml_create(WBXMLConvWBXML2XML **conv);
    
    /**
     * @brief Set the XML generation type (default: WBXML_GEN_XML_INDENT).
     * @param conv     [in] the converter
     * @param gen_type [in] generation type
     */
    WBXML_DECLARE(void) wbxml_conv_wbxml2xml_set_gen_type(WBXMLConvWBXML2XML *conv, WBXMLGenXMLType gen_type);

    /**
     * @brief Set the used WBXML language.
     *        The language is usually detected by the specified public ID in the document.
     *        If the public ID is set then it overrides the language.
     * @param conv [in] the converter
     * @param lang [in] language (e.g. SYNCML12)
     */
    WBXML_DECLARE(void) wbxml_conv_wbxml2xml_set_language(WBXMLConvWBXML2XML *conv, WBXMLLanguage lang);

    /**
     * @brief Set the used character set.
     *        The default character set is UTF-8.
     *        If the document specifies a character set by it own
     *        then this character set overrides the parameter charset.
     * @param conv    [in] the converter
     * @param charset [in] the character set
     */
    WBXML_DECLARE(void) wbxml_conv_wbxml2xml_set_charset(WBXMLConvWBXML2XML *conv, WBXMLCharsetMIBEnum charset);

    /**
     * @brief Set the indent of the generated XML document (please see EXPAT default).
     * @param conv   [in] the converter
     * @param indent [in] the number of blanks
     */
    WBXML_DECLARE(void) wbxml_conv_wbxml2xml_set_indent(WBXMLConvWBXML2XML *conv, WB_UTINY indent);

    /**
     * @brief Enable whitespace preservation (default: FALSE).
     * @param conv     [in] the converter
     */
    WBXML_DECLARE(void) wbxml_conv_wbxml2xml_enable_preserve_whitespaces(WBXMLConvWBXML2XML *conv);

    /**
     * @brief Convert WBXML to XML
     * @param conv      [in] the converter
     * @param wbxml     [in] WBXML Document to convert
     * @param wbxml_len [in] Length of WBXML Document
     * @param xml       [out] Resulting XML Document
     * @param xml_len   [out] XML Document length
     * @return WBXML_OK if conversion succeeded, an Error Code otherwise
     */
    WBXML_DECLARE(WBXMLError) wbxml_conv_wbxml2xml_run(WBXMLConvWBXML2XML *conv,
                                                       WB_UTINY  *xml,
                                                       WB_ULONG   xml_len,
                                                       WB_UTINY **wbxml,
                                                       WB_ULONG  *wbxml_len);
  
    /**
     * @brief Destroy the converter object.
     * @param [in] the converter
     */
    WBXML_DECLARE(void) wbxml_conv_wbxml2xml_destroy(WBXMLConvWBXML2XML *conv);
    
=end
    
    
    enum :charset, [
      :unknown,     0,
      :ascii,       3,
      
      :utf8,        106
    ]
    
    enum :gen_type, [
      :compact,     0,
      :indent,
      :canonical
    ]
    
    # enum :language, [
    #   :unknown,             0,
    #   :wbxml_lang_wml_10,   1101,
    #   :wbxml_lang_wml_11,   1101,
    #   :wbxml_lang_wml_12,   1101,
    #   :wbxml_lang_wml_13,   1101
    # ]
    
    enum :version, [
      :unknown,              0,
      :v10,               1101,
      :v11,
      :v12,
      :v13,
    ]
    
    # class WBXMLParams < FFI::Struct
    #   layout(
    #       :gen_type,          :gen_type,
    #       :lang,              :language,
    #       :charset,           :charset,
    #       :indent,            :uchar,
    #       :keep_ignorable_ws, :uchar
    #     )
    # end
    
    
    
    enum :wbxml_error, [
      :ok,                          0,
      :not_encoded,
      :attr_error_table_undefined,  10,
      :attr_error_bad_datetime,
      :attr_error_bad_parameter,
      :attr_error_internal,
      
      :strtbl_disabled,             100,
      :unknown_xml_language,
      :xml_node_not_allowed,
      :xml_null_attr_name,
      :xml_parsing_failed
    ]
    
    # attach_function :wbxml_conv_xml2wbxml_withlen, [:pointer, :uint, :pointer, :pointer, :pointer], :wbxml_error
    # attach_function :wbxml_conv_wbxml2xml_withlen, [:pointer, :uint, :pointer, :pointer, :pointer], :wbxml_error
    
    # XML => WBXML
    attach_function :wbxml_conv_xml2wbxml_create, [:pointer], :wbxml_error
    attach_function :wbxml_conv_xml2wbxml_set_version, [:pointer, :version], :wbxml_error
    attach_function :wbxml_conv_xml2wbxml_run, [:pointer, :pointer, :uint, :pointer, :pointer], :wbxml_error
    attach_function :wbxml_conv_xml2wbxml_destroy, [:pointer], :void

    
    # WBXML => XML
    attach_function :wbxml_conv_wbxml2xml_create, [:pointer], :wbxml_error
    # attach_function :wbxml_conv_wbxml2xml_set_language, [:pointer, :language], :wbxml_error
    attach_function :wbxml_conv_wbxml2xml_run, [:pointer, :pointer, :uint, :pointer, :pointer], :wbxml_error
    attach_function :wbxml_conv_wbxml2xml_destroy, [:pointer], :void
    
    
    def self.wbxml_to_xml(buffer)
      # opaque state
      conv = FFI::MemoryPointer.new(:pointer)
      
      if (ret = WBXMLLib.wbxml_conv_wbxml2xml_create(conv)) != :ok
        raise "init error: #{ret}"
      end
      
      conv = conv.get_pointer(0)
      
      begin
        data = FFI::MemoryPointer.new(:uchar, buffer.bytesize)
        data.put_bytes(0, buffer, 0, data.size)
        
        output = FFI::MemoryPointer.new(:pointer)
        output_size = FFI::MemoryPointer.new(:ulong)

        ret = WBXMLLib.wbxml_conv_wbxml2xml_run(conv, data, data.size, output, output_size)
        
        if ret == :ok
          size = output_size.get_uint(0)
          output.get_pointer(0).get_bytes(0, size)
        else
          raise RuntimeError, "failed: #{ret}"
        end
        
      ensure
        WBXMLLib.wbxml_conv_wbxml2xml_destroy(conv)
        
      end
    end    
    
    
    def self.xml_to_wbxml(buffer)    
      # opaque state
      conv = FFI::MemoryPointer.new(:pointer)
      
      if (ret = WBXMLLib.wbxml_conv_xml2wbxml_create(conv)) != :ok
        raise "init error: #{ret}"
      end
      
      conv = conv.get_pointer(0)
      
      begin
        if (ret = WBXMLLib.wbxml_conv_xml2wbxml_set_version(conv, :v13)) != :ok
          raise "init error: #{ret}"
        end
        
        data = FFI::MemoryPointer.new(:uchar, buffer.bytesize)
        data.put_bytes(0, buffer, 0, data.size)
        
        output = FFI::MemoryPointer.new(:pointer)
        output_size = FFI::MemoryPointer.new(:ulong)

        ret = WBXMLLib.wbxml_conv_xml2wbxml_run(conv, data, data.size, output, output_size)
        
        if ret == :ok
          size = output_size.get_uint(0)
          output.get_pointer(0).get_bytes(0, size)
        else
          raise RuntimeError, "failed: #{ret}"
        end
        
      ensure
        WBXMLLib.wbxml_conv_xml2wbxml_destroy(conv)
        
      end
    end
    
  #   def self.xml_to_wbxml(xml_string)
  #     data = FFI::MemoryPointer.new(:uchar, xml_string.bytesize)
  #     data.put_bytes(0, xml_string, 0, data.size)
      
  #     output = FFI::MemoryPointer.new(:pointer)
  #     output_size = FFI::MemoryPointer.new(:ulong)
      
  #     params = WBXMLParams.new
  #     params[:gen_type] = :compact
  #     params[:lang] = :wbxml_lang_wml_13
  #     # params[:lang] = 1104
  #     params[:charset] = :utf8
  #     params[:indent] = 0
  #     params[:keep_ignorable_ws] = 0
      
  #     ret = WBXMLLib.wbxml_conv_xml2wbxml_withlen(data, data.size, output, output_size, params)
      
  #     if ret == :ok
  #       size = output_size.get_uint(0)
  #       output.get_pointer(0).get_bytes(0, size)
  #     else
  #       raise RuntimeError, "failed: #{ret}"
  #     end
  #   end
    
  # end
  
    
  # class WBXMLMiddleware
  #   def call(env)
  #     # plug wbxml
  #   end
  # end
  
  end
end


if __FILE__ == $0
  xml = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE ActiveSync PUBLIC "-//MICROSOFT//DTD ActiveSync//EN" "http://www.microsoft.com/">
<Settings xmlns="Settings:">
  <DeviceInformation>
    <Set>
      <Model>0.11-beta</Model>
      <IMEI>1234567890</IMEI>
      <FriendlyName>Test Device</FriendlyName>
      <OS>Linux</OS>
      <OSLanguage>de_DE</OSLanguage>
      <PhoneNumber>+49301234567890</PhoneNumber>
      <MobileOperator>O2</MobileOperator>
      <UserAgent>libwbxml</UserAgent>
    </Set>
  </DeviceInformation>
</Settings>
EOS
  data =  AS::WBXMLLib.xml_to_wbxml(xml)
  p data
  
  # data = File.read('/tmp/out.txt')
  puts AS::WBXMLLib.wbxml_to_xml(data)
end
