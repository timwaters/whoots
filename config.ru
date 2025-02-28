require 'rack'
require 'rack/protection'

require_relative './whoots_app'

# Add security headers
use Rack::Protection
use Rack::Protection::XSSHeader
use Rack::Protection::FrameOptions

#use Rack::Reloader, 0  #<=- useful to uncomment for dev
use Rack::Static, :urls => [""], :root => "public", :index => 'index.html'
#use Rack::Directory, :index => 'index.html' 

run WhootsApp