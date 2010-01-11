require 'open-uri'
require 'nokogiri'

$: << File.dirname(__FILE__)
require 'csteamer/document'

module CSteamer
  # Sugar method to make creating document objects nicer
  def self.document(handle, url = nil)
    Document.new(handle, url)
  end
end

class Nokogiri::HTML::Document
  def get_the(search)
    self.search(search).first rescue nil
  end
  
  def match(*queries)
    queries.each do |query|
      if query.is_a?(String)
        result = self.search(query).first.inner_text.strip rescue nil
      elsif query.is_a?(Array)
        result = query[1].call(self.search(query.first).first).strip rescue nil
      end
      return result if result
    end
    return nil
  end
end

class Nokogiri::XML::Element
  def attr_text(attr)
    self.attr(attr).inner_text rescue nil
  end
end