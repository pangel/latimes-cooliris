require 'sinatra'
require 'environment'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

helpers do
  def parse_request(query,page)

    tmp_file = File.join(TMP_FOLDER, "#{query}#{page}")

    if File.exist? tmp_file
      File.open(tmp_file) do |file|
        @file = true
        return Marshal.load file
      end
    end

    elements = []
    @req = "http://unitproj.library.ucla.edu/dlib/lat/search.cfm?k=#{query}&w=none&x=title&y=none&z=none&s=#{page}"
    doc = Hpricot(open @req)
    (doc/'a[@href^="display.cfm"]').each do |el|
      elements << el if (not el.at("img").nil?)
    end
    elements.map! do |el|
      {:src => el.at("img")[:src], :legend => el.following_siblings[1].inner_text }
    end

    File.open tmp_file, "w" do |file|
      Marshal.dump elements, file
    end

    return elements
  end
  
  def rss_url(q,p)
    "/rss?" + build_query(:q => q, :p => p)
  end

  # From http://github.com/cschneid/irclogger/blob/master/lib/partials.rb
  def partial(template, *args)
    options = *args
    options.merge!(:layout => false)
    if collection = options.delete(:collection) then
      collection.inject([]) do |buffer, member|
        buffer << haml(template, options.merge(:layout => false, :locals => {template.to_sym => member}))
    end.join("\n")
    else
      haml(template, options)
    end
  end
end

before do
  # response["Content-Type"] = "text/html; charset=utf-8"
end

get '/' do
  q = params["q"] || ""
  p = params["p"] || 1
  @results = parse_request(q,p) unless q.empty?
  haml :search, :locals => {:q => q, :p => p}
end

get '/rss' do
  q,p = params["q"], params["p"]
  pn = p.to_i
  content = parse_request(q,p)

  x = Builder::XmlMarkup.new(:indent=>2)
  x.instruct!
  x << '<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss"   xmlns:atom="http://www.w3.org/2005/Atom">'
  x.channel {
    x.atom :link, {"rel" => "previous", "href" => rss_url(q,pn-1)} unless pn <= 1
    x.atom :link, {"rel" => "next", "href" => rss_url(q, pn+1)}
    x.title "UCLA!"
    x.language "en-US"
    content.each { |pic|
      x.item {
        x.title pic[:legend]
        x.link pic[:src].sub(/i\.gif/, "j.jpg")
        x.media :thumbnail, {"url"=>pic[:src], "type" => "image/gif"}
        x.media :content, {"url"=>pic[:src].sub(/i\.gif/, "j.jpg"), "type" => "image/jpeg"}
      }
    }
  }
  x << '</rss>'
end
  
get '/stylesheets/style.css' do
  response["Content-Type"] = "text/css; charset=utf-8" 
  sass :style
end