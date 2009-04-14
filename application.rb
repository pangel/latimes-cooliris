require 'sinatra'
require 'environment'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

helpers do
  def parse_request(query)
    elements = []
    doc =   Hpricot(open("http://unitproj.library.ucla.edu/dlib/lat/search.cfm?k=#{query}&w=none&x=title&y=none&z=none&s=2"))
    el = (doc/'a[@href^="display.cfm"]').each do |e|
      elements << e if (not e.at("img").nil?)
    end
    elements.map do |a|
      [a.at("img")[:src],a.following_siblings[1].inner_text]
    end
  end
end

before do
  # response["Content-Type"] = "text/html; charset=utf-8"
end

get '/' do
  @q = params["q"].nil? ? "" : params["q"]
  @rss_postfix = @q.empty? ? "" : "?q=#{@q}"
  haml :search
end

get '/rss' do
  content = parse_request(params["q"])
  
  x = Builder::XmlMarkup.new(:indent=>2)
  x.instruct!
  x << '<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss"   xmlns:atom="http://www.w3.org/2005/Atom">'
  x.channel {
    x.title "UCLA!"
    x.language "en-US"
    content.each { |pic|
      x.item {
        x.title pic[1]
        x.link pic[0].sub(/i\.gif/, "j.jpg")
        x.media :thumbnail, {"url"=>pic[0], "type" => "image/gif"}
        x.media :content, {"url"=>pic[0].sub(/i\.gif/, "j.jpg"), "type" => "image/jpeg"}
      }
    }
  }
  x << '</rss>'
end
  
get '/stylesheets/style.css' do
  response["Content-Type"] = "text/css; charset=utf-8" 
  sass :style
end