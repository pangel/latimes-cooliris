require 'sinatra'
require 'environment'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

helpers ApplicationHelpers

get '/' do
  @q, @p = parse_params(params)
  @results = parse_request(@q,@p) unless @q.empty?
  haml :search
end

get '/img' do
  @q = params["q"]
  n = params["n"].to_i
  
  @p, index = get_page_and_index_from_id n

  @img = parse_request(@q,@p)[index]
  haml :img, :locals => {:q => @q, :p => @p, :n => n}
end

get '/rss' do
  q,p = parse_params(params)
  content = parse_request(q,p)

  x = Builder::XmlMarkup.new(:indent=>2)
  x.instruct!
  x << '<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss"   xmlns:atom="http://www.w3.org/2005/Atom">'
  x.channel {
    x.atom :link, {"rel" => "previous", "href" => rss_url(q,p-1)} unless p <= 1
    x.atom :link, {"rel" => "next", "href" => rss_url(q, p+1)}
    x.title "UCLA!"
    x.language "en-US"
    content.each { |pic|
      x.item {
        x.title pic[:legend]
        x.link pic[:large]
        x.media :thumbnail, {"url"=>pic[:thumb], "type" => "image/gif"}
        x.media :content, {"url"=>pic[:large], "type" => "image/jpeg"}
      }
    }
  }
  x << '</rss>'
end
  
get '/stylesheets/style.css' do
  response["Content-Type"] = "text/css; charset=utf-8" 
  sass :style
end