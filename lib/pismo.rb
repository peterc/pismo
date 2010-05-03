# encoding: utf-8

require 'open-uri'
require 'nokogiri'
require 'fast_stemmer'
require 'chronic'

$: << File.dirname(__FILE__)
require 'pismo/document'
require 'pismo/readability'

module Pismo
  # Sugar method to make creating document objects nicer
  def self.document(handle, url = nil)
    Document.new(handle, url)
  end
  
  class NFunctions
    def self.match_href(list, expression)
      list.find_all { |node| node['href'] =~ /#{expression}/ }
    end
  end
end

# Add some sugar to Nokogiri
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

      if result
      #  result.gsub!(/\342\200\231/, '\'')
      #  result.gsub!(/\342\200\224/, '-')
        result.gsub!('’', '\'')
        result.gsub!('—', '-')
        return result
      end
    end
    return nil
  end
end