module GoogleCustomSearch

  ##
  # Search result data.
  #
  class ResultSet < Struct.new(:pages, :results); end

  ##
  # Single search result data.
  #
  class Result < Struct.new(:url, :title, :description); end

  ##
  # Pages data
  #

  class Start < Struct.new(:start, :label); end

  ##
  # Search the site.
  #
  def self.search(query, start)
    # Get and parse results.
    url = url(query, start)
    json = fetch_json(url)
    data = Crack::JSON.parse(json)

    # Extract and return pages data and search result data.
    if data['responseData']
      if data['responseData']['cursor']['pages']
        ResultSet.new(
          parse_start(data['responseData']['cursor']['pages']),          
          parse_results(data['responseData']['results'])                 
        )
      else
        ResultSet.new(
          false,          #return false if pages < 1
          parse_results(data['responseData']['results'])
        )
      end
    else
      ResultSet.new(0, [])
    end
  end
  
  
  private
  
  ##
  # Build search request URL.
  #
  def self.url(query, start)
    query = CGI::escape(query)
    "http://www.google.com/uds/GwebSearch?context=0&lstkp=0&rsz=filtered_cse&hl=ru&source=gcsc&gss=.com&cx=#{CX_GOOGLE_CSE}&q=#{query}&start=#{start}&v=1.0"
  end
  
  ##
  # Query Google.
  #
  def self.fetch_json(url)
    begin
      resp = nil
      timeout(3) do
        resp = Net::HTTP.get_response(URI.parse(url))
      end
   rescue SocketError, TimeoutError; 
    end
    (resp and resp.code == "200") ? resp.body : nil
  end
  
  ##
  # Transform an array of Google search results into
  # a more useful format.
  #
  def self.parse_results(results)
    out = []
    results = results
    results.each do |r|
      out << Result.new(
        r['url'],                         # url
        r['title'],                       # title
        r['content']                      # desciption
      )
    end
    out
  end

  ##
  # Transform an array of Google pages info into
  # a mare useful format.

  def self.parse_start(results)
    out = []
    results = results
    results.each do |r|
      out << Start.new(
      r['start'],                         # pages start
      r['label']                          # pages label
      )
    end
    out
  end
end

