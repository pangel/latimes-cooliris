module ApplicationHelpers
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
      thumb = el.at("img")[:src]
      large = el.at("img")[:src].sub(/i\.gif/, "j.jpg")
      legend = el.following_siblings[1].inner_text
      {:thumb => thumb, :large => large, :legend => legend}
    end

    File.open tmp_file, "w" do |file|
      Marshal.dump elements, file
    end
    return elements
  end

  def url(root, *args)
    options = *args
    anchor = options.delete(:anchor)
    anchor = "##{anchor}" unless anchor.nil?
    "/#{root}?" + build_query(*args) + anchor.to_s
  end

  def rss_url(q,p)
    url 'rss', :q => q, :p => p
  end

  def partial(template, *args)
    options = *args
    options.merge!(:layout => false)
    if collection = options.delete(:collection) then
      buffer = []
      collection.each_with_index do |member, index|
        buffer << haml(template, options.merge(:layout => false, :locals => {template.to_sym => member, :_counter => index}))
      end
      buffer.join("\n")
    else
      haml(template, options)
    end
  end

  def get_page_and_index_from_id(id)

    # Extracting current page from image id.
    # E.g Image#13 is on page 1 (13/10 = 1)
    #     Image#29 is on page 2 (19/10 = 2)
    page = id/10

    # Extracting image index from image id.
    # E.g Image#13 is n.3 of page 1 (13 - (1*10) = 3)
    #     Image#29 is n.9 of page 2 (29 - (2*10) = 9)
    index = id - (page*10)

    return page,index
  end

  def parse_params(params)
    q = params["q"] || ""
    p = (params["p"] || 1).to_i
    return q,p
  end
end