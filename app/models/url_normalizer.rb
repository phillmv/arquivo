require 'uri'

class UrlNormalizer
  attr_reader :url
  def initialize(url)
    @url = url
  end

  def to_s
    begin
      uri = URI.parse(url)
    rescue URI::InvalidURIError
      # handle invalid input, e.g. by returning the original URL
      return url
    end

    case uri.host
    when 'docs.google.com'
      uri.fragment = nil
    when 'github.com'
      if uri.path =~ /pull\/\d+\/files/
        uri.path = uri.path.sub(/files.*$/, '')
        # handles having a #diff after
        uri.fragment = nil
      end
    end

    uri.path = uri.path.sub(/\/$/, '')
    uri.to_s
  end
end
