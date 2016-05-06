$:.unshift File.dirname(__FILE__)
require 'whoots_app'
#use Rack::Reloader, 0  #<=- useful to uncomment for dev
use Rack::Static, :urls => ["/images"], :root => "public", :index => 'index.html'

run WhootsApp