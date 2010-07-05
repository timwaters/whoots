require 'rubygems'
require 'vendor/rack/lib/rack'
require 'vendor/sinatra/lib/sinatra'
  
set :run, false
set :environment, :production
set :views, "views"
  
require 'whoots.rb'
run Sinatra::Application

