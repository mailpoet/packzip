require "rubygems"
require "bundler"
Bundler.require(:app)
require './app'
run Sinatra::Application
