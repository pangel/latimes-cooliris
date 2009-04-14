class TagCollection < Array
  def initialize(params)
    @tag_name = params.kind_of?(Hash) ? params[:tag_name] : params
  end
  
  def to_xml
    string = ""
    self.map { |item|
      item_attributes = item[:attributes].inject("") { |acc,att| 
        acc << " #{att.first}='#{att.last}'"  
      }
    
      item_tag = "#{@tag_name}:#{item[:sub]}"
      item_string = "<#{item_tag}#{item_attributes}"
    
      if item[:content].empty?
        item_string << "/>"
      else
        item_string << ">#{item[:content]}</#{item_tag}>"
      end
      item_string = "<!-- #{item_string} -->" if item[:comment]
      item_string+"\n"
    }.join('')
  end
    
  
  def push(sub="", content="",attributes={}, comment=false)
    super({:sub => sub, :content => content, :attributes => attributes, :comment => comment})
  end
end

class CoolIris
  attr_accessor :title,:link,:language,:copyright
  
  def initialize
    @title,@link,@language,@copyright = "[UNDEFINED]"
    @atoms = TagCollection.new :tag_name => "atom"
    @items = []
    yield(self)
  end
  
  class Item
    attr_accessor :title, :link
   
    def initialize(block)
      @title,@link = "[UNDEFINED]"
      @medias = TagCollection.new :tag_name => "media"
      block.call(self)
    end
      
    def media(*args)
      @medias.push(*args)
    end
    
    def to_xml
      feed = <<-EOS
               <item>
               <title>#{title}</title>
               <link>#{link}</link>
             EOS
             
      feed << @medias.to_xml
      
      feed << <<-EOS
                </item>
              EOS
    end  
  end

  def atom(*args)
    @atoms.push(*args)
  end
  
  def item(&block)
    @items << Item.new(block)
  end
    
  def to_xml
    feed = <<-EOS
      <?xml version="1.0" encoding="utf-8"?>
      <rss version="2.0" xmlns:media="http://search.yahoo.com/mrss" xmlns:atom="http://www.w3.org/2005/Atom">
      <channel>
      <title>#{title}</title>
      <language>#{language}</language>
      <copyright>#{copyright}</copyright>
      
  EOS
  
     feed << @atoms.to_xml
     
     @items.each { |item|
       feed << item.to_xml
     }
     
    feed << <<-EOS
            </channel>
            </rss>
            EOS
  end
end

if __FILE__ == $0
  a = CoolIris.new do |feed|
    feed.title = "TITLE"
    feed.link = "LINK"
    feed.language = "LANGUAGE"
    feed.copyright = "COPYRIGHT"
    feed.atom "icon", "ICONURL"
    feed.atom "link", "", {"rel" => "next", "href" => "HREFLINKREL"}  
    feed.atom "link", "", {"rel" => "previous", "href" => "HREFLINKREL"}, true

    %w[pic1 pic2 pic3].each do |pic|
      feed.item do |item|
        item.title = pic
        item.link = pic+"LINK"
        item.media "thumbnail", "", {"url" => "URL", "type" => "image/jpeg"}
      end
    end
  end

  puts a.to_xml
end

