require 'rubygems'
require 'bundler/setup'

require 'eetee'

$LOAD_PATH.unshift( File.expand_path('../../lib' , __FILE__) )
require 'as'

require 'eetee/ext/mocha'
require 'eetee/ext/rack'
# require 'bacon/ext/em'

# Thread.abort_on_exception = true
