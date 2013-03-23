require_relative 'as/version'
require_relative 'as/wbxml'
require_relative 'as/wbxml_lib'
require_relative 'as/state'
require_relative 'as/request'

require_relative 'as/helpers/xml'

require_relative 'as/watcher'
require_relative 'as/handler'
require_relative 'as/command'
require_relative 'as/formatters/contact'
require_relative 'as/commands/folder_sync'
require_relative 'as/commands/sync'
require_relative 'as/commands/ping'
require_relative 'as/commands/search'


module AS
  UnknownFolderId = Class.new(RuntimeError)
end
