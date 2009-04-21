require 'rubygems'
require 'haml'
require 'hpricot'
require 'builder'
require 'open-uri'
require 'sinatra' unless defined?(Sinatra)



configure do
  # Constants
  PROJECT_NAME = "latimes-cooliris"
  TMP_FOLDER = "#{File.dirname(__FILE__)}/tmp"
  
  # Load extensions
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| require File.basename(lib, '.*') }

end

configure :development do

end