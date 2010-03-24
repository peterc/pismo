module Pismo
  # External attributes return data that comes from external services or programs (e.g. Delicious tags)
  module ExternalAttributes
    #include HTTParty
    #
    #def delicious_tags
    #  delicious_info["top_tags"].sort_by { |k, v| v }.reverse.first(5) rescue []
    #end
    #
    #def delicious_info
    #  @delicious_info ||= self.class.get('http://feeds.delicious.com/v2/json/urlinfo/' + Digest::MD5.hexdigest(@url)).first rescue nil
    #end
  end
end