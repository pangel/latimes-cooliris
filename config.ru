require 'application'

set :run, false
set :environment, (ENV['DATABASE_URL'] ? :production : :development)

run Sinatra::Application